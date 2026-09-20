import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../model/app_user.dart';
import '../model/daily_checkin.dart';
import '../model/sync_status.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_config.dart';
import '../services/firestore_sync_service.dart';
import '../services/google_sso_service.dart';
import '../services/watch_auth_bridge.dart';
import 'sync_merger.dart';
import 'sync_state.dart';

export 'sync_auth_coordinator.dart';
export 'sync_merger.dart';
export 'sync_providers.dart';
export 'sync_state.dart';

/// Controller that manages Dual-Layer Persistence:
/// 1. Instant local storage write (handled by TaskStateNotifier)
/// 2. 1,000ms debounced Cloud Firestore synchronization
/// 3. Bi-directional cloud hydration upon sign-in.
class SyncController extends Notifier<SyncState> with WidgetsBindingObserver {
  final Ref? _configuredRef;
  final FirebaseAuthService? _configuredAuthService;
  final FirestoreSyncService? _configuredFirestoreService;
  final FirebaseConfig _initialConfig;
  final AppUser? _initialUser;
  final bool _autoInit;

  FirebaseAuthService? _authService;
  FirestoreSyncService? _firestoreService;
  Timer? _debounceTimer;
  Timer? _pollingTimer;
  bool _isSyncing = false;
  GoogleSsoService? activeSsoService;
  SyncState? _standaloneState;

  FirebaseAuthService get authService =>
      _authService ?? _configuredAuthService ?? FirebaseAuthService(config: state.config);
  FirestoreSyncService get firestoreService =>
      _firestoreService ?? _configuredFirestoreService ?? FirestoreSyncService(config: state.config);

  SyncController({
    Ref? ref,
    FirebaseAuthService? authService,
    FirestoreSyncService? firestoreService,
    FirebaseConfig initialConfig = const FirebaseConfig(),
    AppUser? initialUser,
    bool autoInit = true,
  })  : _configuredRef = ref,
        _configuredAuthService = authService,
        _configuredFirestoreService = firestoreService,
        _initialConfig = initialConfig,
        _initialUser = initialUser,
        _autoInit = autoInit;

  @override
  SyncState build() {
    _authService = _configuredAuthService ?? FirebaseAuthService(config: _initialConfig);
    _firestoreService = _configuredFirestoreService ?? FirestoreSyncService(config: _initialConfig);

    ref.onDispose(() {
      _debounceTimer?.cancel();
      stopPeriodicSync();
      activeSsoService?.cancel();
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    });

    if (_autoInit) {
      Future.microtask(() => _init());
    }

    return SyncState(
      config: _initialConfig,
      user: _initialUser,
      status: _initialUser != null ? SyncStatus.synced : SyncStatus.guest,
      configLoaded: _initialConfig.isConfigured,
    );
  }

  @override
  SyncState get state {
    try {
      return super.state;
    } catch (_) {
      return _standaloneState ??= SyncState(
        config: _initialConfig,
        user: _initialUser,
        status: _initialUser != null ? SyncStatus.synced : SyncStatus.guest,
        configLoaded: _initialConfig.isConfigured,
      );
    }
  }

  @override
  set state(SyncState value) {
    try {
      super.state = value;
    } catch (_) {
      _standaloneState = value;
    }
  }

  Ref get _activeRef => _configuredRef ?? ref;

  Future<void> _init() async {
    final loadedConfig = await FirebaseConfig.load();
    if (loadedConfig.isConfigured) {
      authService.config = loadedConfig;
      firestoreService.config = loadedConfig;
      state = state.copyWith(config: loadedConfig, configLoaded: true);
    } else {
      state = state.copyWith(configLoaded: true);
    }

    try {
      final taskNotifier = _activeRef.read(taskStateProvider.notifier);
      taskNotifier.onTasksPersisted = _handleLocalTasksChanged;
    } catch (_) {}

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    if (state.user != null) {
      startPeriodicSync();
    }

    final cachedUser = await FirebaseAuthService.loadCachedUser();
    if (cachedUser != null && state.user == null) {
      await onUserAuthenticated(cachedUser);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.isSignedIn) {
      syncNow();
    }
  }

  void startPeriodicSync() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.isSignedIn && !_isSyncing) {
        performTwoWaySync();
      }
    });
  }

  void stopPeriodicSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void cancelDebounce() {
    _debounceTimer?.cancel();
  }


  void _handleLocalTasksChanged(List<PinTask> tasks) {
    if (state.user == null) {
      if (state.status != SyncStatus.guest) {
        state = state.copyWith(status: SyncStatus.guest);
      }
      return;
    }
    state = state.copyWith(isDebouncing: true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _debounceTimer = null;
      state = state.copyWith(isDebouncing: false);
      performTwoWaySync();
    });
  }

  Future<void> syncNow() async {
    if (!state.isSignedIn) return;
    _debounceTimer?.cancel();
    state = state.copyWith(isDebouncing: false);
    await performTwoWaySync();
  }

  Future<void> performTwoWaySync() async {
    final user = state.user;
    if (user == null || _isSyncing) return;

    _isSyncing = true;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);

    try {
      final taskNotifier = _activeRef.read(taskStateProvider.notifier);
      await taskNotifier.loadFuture;
      final localTasks = _activeRef.read(taskStateProvider).tasks;
      final localDeletedMap = taskNotifier.deletedTaskIds;

      final cloudBoard = await firestoreService.loadBoardFromFirestore(
        userId: user.uid,
        idToken: user.idToken,
      );

      if (cloudBoard == null) {
        await _pushAndApplyResult(
          userId: user.uid,
          idToken: user.idToken,
          tasks: localTasks,
          checkin: state.dailyCheckin,
          deletedIds: localDeletedMap,
        );
        _isSyncing = false;
        return;
      }

      final mergeResult = SyncMerger.reconcile(
        localTasks: localTasks,
        localDeletedMap: localDeletedMap,
        cloudBoard: cloudBoard,
        currentCheckin: state.dailyCheckin,
        lastSyncedAt: state.lastSyncedAt,
      );

      taskNotifier.mergeDeletedTaskIds(mergeResult.mergedDeletedMap);

      if (SyncMerger.hasListChanged(localTasks, mergeResult.mergedTasks)) {
        await taskNotifier.hydrateFromCloud(mergeResult.mergedTasks);
      }

      await _pushAndApplyResult(
        userId: user.uid,
        idToken: user.idToken,
        tasks: mergeResult.mergedTasks,
        checkin: mergeResult.checkin,
        deletedIds: mergeResult.mergedDeletedMap,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Sync failed: ${e.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushAndApplyResult({
    required String userId,
    required String? idToken,
    required List<PinTask> tasks,
    required DailyCheckin? checkin,
    required Map<String, int> deletedIds,
  }) async {
    final result = await firestoreService.syncBoardToFirestore(
      userId: userId,
      idToken: idToken,
      tasks: tasks.map((t) => t.toJson()).toList(),
      dailyCheckin: checkin?.toJson(),
      deletedTaskIds: deletedIds,
    );
    state = result.success
        ? state.copyWith(
            status: SyncStatus.synced,
            lastSyncedAt: result.syncedAt,
            syncedTaskCount: tasks.length,
            dailyCheckin: checkin,
            clearError: true,
          )
        : state.copyWith(status: SyncStatus.error, errorMessage: result.errorMessage);
  }

  Future<void> onUserAuthenticated(AppUser user) async {
    state = state.copyWith(user: user, status: SyncStatus.syncing, clearError: true);
    unawaited(WatchAuthBridge().sendAuthToWatch(user));
    startPeriodicSync();
    await performTwoWaySync();
  }

  Future<void> updateDailyCheckin(DailyCheckin checkin) async {
    state = state.copyWith(dailyCheckin: checkin);
    if (state.user != null) {
      final tasks = _activeRef.read(taskStateProvider).tasks;
      _handleLocalTasksChanged(tasks);
    }
  }

  Future<void> updateConfig(FirebaseConfig newConfig) async {
    await newConfig.save();
    authService.config = newConfig;
    firestoreService.config = newConfig;
    state = state.copyWith(config: newConfig);
  }
}
