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

/// Immutable state containing active user, sync status, and metadata.
class SyncState {
  final AppUser? user;
  final SyncStatus status;
  final int? lastSyncedAt;
  final String? errorMessage;
  final DailyCheckin? dailyCheckin;
  final FirebaseConfig config;
  final int syncedTaskCount;
  final bool isDebouncing;

  /// Whether the persisted FirebaseConfig has been loaded from SharedPreferences.
  /// Auth actions are blocked until this is true to prevent the "Firebase is
  /// not configured" race condition on real devices where storage I/O is slow.
  final bool configLoaded;

  const SyncState({
    this.user,
    this.status = SyncStatus.guest,
    this.lastSyncedAt,
    this.errorMessage,
    this.dailyCheckin,
    required this.config,
    this.syncedTaskCount = 0,
    this.isDebouncing = false,
    this.configLoaded = false,
  });

  bool get isSignedIn => user != null;

  SyncState copyWith({
    AppUser? user,
    bool clearUser = false,
    SyncStatus? status,
    int? lastSyncedAt,
    String? errorMessage,
    bool clearError = false,
    DailyCheckin? dailyCheckin,
    FirebaseConfig? config,
    int? syncedTaskCount,
    bool? isDebouncing,
    bool? configLoaded,
  }) {
    return SyncState(
      user: clearUser ? null : (user ?? this.user),
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dailyCheckin: dailyCheckin ?? this.dailyCheckin,
      config: config ?? this.config,
      syncedTaskCount: syncedTaskCount ?? this.syncedTaskCount,
      isDebouncing: isDebouncing ?? this.isDebouncing,
      configLoaded: configLoaded ?? this.configLoaded,
    );
  }
}

/// Controller that manages Dual-Layer Persistence:
/// 1. Instant local storage write (handled by TaskStateNotifier)
/// 2. 1,000ms debounced Cloud Firestore synchronization
/// 3. Bi-directional cloud hydration upon sign-in.
class SyncController extends StateNotifier<SyncState> with WidgetsBindingObserver {
  final Ref _ref;
  final FirebaseAuthService authService;
  final FirestoreSyncService firestoreService;
  Timer? _debounceTimer;
  Timer? _pollingTimer;
  bool _isSyncing = false;

  SyncController({
    required Ref ref,
    required this.authService,
    required this.firestoreService,
    required FirebaseConfig initialConfig,
    AppUser? initialUser,
  })  : _ref = ref,
        super(SyncState(
          config: initialConfig,
          user: initialUser,
          status: initialUser != null ? SyncStatus.synced : SyncStatus.guest,
          configLoaded: initialConfig.isConfigured,
        )) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load persisted Firebase config FIRST — before any auth action is
    //    possible — to eliminate the race condition on real devices where
    //    SharedPreferences I/O completes after the first frame is rendered.
    final loadedConfig = await FirebaseConfig.load();
    if (loadedConfig.isConfigured) {
      authService.config = loadedConfig;
      firestoreService.config = loadedConfig;
      state = state.copyWith(config: loadedConfig, configLoaded: true);
    } else {
      state = state.copyWith(configLoaded: true);
    }

    // 2. Hook into TaskStateNotifier persistence callback
    final taskNotifier = _ref.read(taskStateProvider.notifier);
    taskNotifier.onTasksPersisted = _handleLocalTasksChanged;

    // 3. Register lifecycle observer for auto-sync on app resume / window focus
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // 4. Start periodic sync if already signed in
    if (state.user != null) {
      _startPeriodicSync();
    }

    // 5. Hydrate cached session if exists
    final cachedUser = await FirebaseAuthService.loadCachedUser();
    if (cachedUser != null && state.user == null) {
      await _onUserAuthenticated(cachedUser);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.isSignedIn) {
      syncNow();
    }
  }

  void _startPeriodicSync() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.isSignedIn && !_isSyncing) {
        _performTwoWaySync();
      }
    });
  }

  void _stopPeriodicSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Returns true if config is loaded; otherwise sets an error and returns false.
  bool _guardConfigLoaded() {
    if (state.configLoaded || state.config.isConfigured) {
      return true;
    }
    state = state.copyWith(
      errorMessage: 'Connecting to Firebase… please try again in a moment.',
    );
    return false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _stopPeriodicSync();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }

  /// Called whenever tasks are updated and persisted locally.
  void _handleLocalTasksChanged(List<PinTask> tasks) {
    if (state.user == null) {
      // In Guest Mode: local storage already persisted; no cloud write needed.
      if (state.status != SyncStatus.guest) {
        state = state.copyWith(status: SyncStatus.guest);
      }
      return;
    }

    // Debounce the cloud sync by exactly 1,000 milliseconds
    _debounceTimer?.cancel();
    state = state.copyWith(isDebouncing: true);

    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      await _performTwoWaySync();
    });
  }

  /// Forces an immediate bi-directional cloud sync, cancelling any pending debounce timer.
  Future<void> syncNow() async {
    _debounceTimer?.cancel();
    await _performTwoWaySync();
  }

  /// Executes full bi-directional synchronization with Cloud Firestore:
  /// 1. Fetches current cloud state (`loadBoardFromFirestore`).
  /// 2. Merges deletion tombstones (`deletedTaskIds`) to prevent resurrected tasks across devices.
  /// 3. Merges tasks via CRDT / Last-Write-Wins (LWW) based on `updatedAt`.
  /// 4. Filters out unedited initial sample pins if real tasks exist, preventing dummy data pollution.
  /// 5. Hydrates local storage if remote changes occurred.
  /// 6. Pushes the unified board snapshot and tombstones to Firestore.
  Future<void> _performTwoWaySync() async {
    var user = state.user;
    if (user == null) return;
    if (_isSyncing) return;
    _isSyncing = true;

    state = state.copyWith(
      status: SyncStatus.syncing,
      isDebouncing: false,
      clearError: true,
    );

    // Refresh the ID token if it has expired (Firebase tokens last 1 hour).
    if (state.config.isConfigured &&
        user.refreshToken != null &&
        user.refreshToken!.isNotEmpty &&
        user.isTokenExpired) {
      try {
        final freshUser = await authService.freshIdToken(user);
        if (freshUser != user) {
          // Token was refreshed — persist the updated user in state and cache.
          user = freshUser;
          state = state.copyWith(user: freshUser);
        }
      } catch (e) {
        await signOut();
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Session expired. Please sign in again.',
        );
        _isSyncing = false;
        return;
      }
    }

    try {
      final taskNotifier = _ref.read(taskStateProvider.notifier);
      await taskNotifier.loadFuture;
      final localTasks = _ref.read(taskStateProvider).tasks;
      final localDeletedMap = taskNotifier.deletedTaskIds;

      // 1. Fetch cloud snapshot
      final cloudBoard = await firestoreService.loadBoardFromFirestore(
        userId: user.uid,
        idToken: user.idToken,
      );

      final checkinMap = state.dailyCheckin?.toJson();

      if (cloudBoard == null) {
        // Document does not exist on cloud yet — seed cloud with local tasks
        final result = await firestoreService.syncBoardToFirestore(
          userId: user.uid,
          idToken: user.idToken,
          tasks: localTasks.map((t) => t.toJson()).toList(),
          dailyCheckin: checkinMap,
          deletedTaskIds: localDeletedMap,
        );
        if (result.success) {
          state = state.copyWith(
            status: SyncStatus.synced,
            lastSyncedAt: result.syncedAt,
            syncedTaskCount: result.count,
            clearError: true,
          );
        } else {
          state = state.copyWith(
            status: SyncStatus.error,
            errorMessage: result.errorMessage,
          );
        }
        _isSyncing = false;
        return;
      }

      // 2. Combine deletion tombstones from cloud and local
      final mergedDeletedMap = Map<String, int>.from(cloudBoard.deletedTaskIds);
      for (final entry in localDeletedMap.entries) {
        final existing = mergedDeletedMap[entry.key];
        if (existing == null || entry.value > existing) {
          mergedDeletedMap[entry.key] = entry.value;
        }
      }
      taskNotifier.mergeDeletedTaskIds(mergedDeletedMap);

      // 3. Parse cloud tasks
      final cloudTasks = cloudBoard.tasks
          .map((m) => PinTask.fromJson(m))
          .toList();

      final cloudHasRealTasks = cloudTasks.any((t) => !TaskStateNotifier.isUntouchedSamplePin(t));
      final localHasRealTasks = localTasks.any((t) => !TaskStateNotifier.isUntouchedSamplePin(t));

      // 4. Merge tasks using CRDT / LWW (Last-Write-Wins)
      final Map<String, PinTask> merged = {};

      // Filter local tasks
      final effectiveLocalTasks = localTasks.where((t) {
        if (cloudHasRealTasks && TaskStateNotifier.isUntouchedSamplePin(t)) {
          return false;
        }
        final deletedAt = mergedDeletedMap[t.id];
        if (deletedAt != null && deletedAt >= t.updatedAt.millisecondsSinceEpoch) {
          return false;
        }
        return true;
      });

      for (final t in effectiveLocalTasks) {
        merged[t.id] = t;
      }

      // Filter cloud tasks
      final effectiveCloudTasks = cloudTasks.where((t) {
        if (localHasRealTasks && TaskStateNotifier.isUntouchedSamplePin(t)) {
          return false;
        }
        final deletedAt = mergedDeletedMap[t.id];
        if (deletedAt != null && deletedAt >= t.updatedAt.millisecondsSinceEpoch) {
          return false;
        }
        return true;
      });

      for (final cloudTask in effectiveCloudTasks) {
        final local = merged[cloudTask.id];
        if (local == null) {
          // Task only in cloud (created on another device) → add it
          merged[cloudTask.id] = cloudTask;
        } else if (cloudTask.updatedAt.isAfter(local.updatedAt)) {
          // Cloud version is newer → prefer cloud
          merged[cloudTask.id] = cloudTask;
        }
        // else: local version is newer or equal → keep local
      }

      final mergedList = merged.values.toList();

      // 5. Update local storage if needed
      if (_hasListChanged(localTasks, mergedList)) {
        await taskNotifier.hydrateFromCloud(mergedList);
      }

      // 6. Merge daily check-in
      DailyCheckin? checkin = state.dailyCheckin;
      if (cloudBoard.dailyCheckin != null && cloudBoard.dailyCheckin!.isNotEmpty) {
        final cloudCheckin = DailyCheckin.fromJson(cloudBoard.dailyCheckin!);
        if (checkin == null || cloudBoard.lastSyncedAt > (state.lastSyncedAt ?? 0)) {
          checkin = cloudCheckin;
        }
      }

      // 7. Push merged result back to Firestore
      final pushResult = await firestoreService.syncBoardToFirestore(
        userId: user.uid,
        idToken: user.idToken,
        tasks: mergedList.map((t) => t.toJson()).toList(),
        dailyCheckin: checkin?.toJson(),
        deletedTaskIds: mergedDeletedMap,
      );

      if (pushResult.success) {
        state = state.copyWith(
          status: SyncStatus.synced,
          lastSyncedAt: pushResult.syncedAt,
          syncedTaskCount: mergedList.length,
          dailyCheckin: checkin,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: pushResult.errorMessage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Sync failed: ${e.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }

  bool _hasListChanged(List<PinTask> a, List<PinTask> b) {
    if (a.length != b.length) return true;
    final mapA = {for (final t in a) t.id: t};
    for (final tb in b) {
      final ta = mapA[tb.id];
      if (ta == null) return true;
      if (ta.updatedAt.millisecondsSinceEpoch != tb.updatedAt.millisecondsSinceEpoch) return true;
      if (ta.status != tb.status) return true;
      if (ta.title != tb.title) return true;
    }
    return false;
  }

  /// Called when a user successfully authenticates. Coordinates cloud hydration
  /// using full bi-directional synchronization.
  Future<void> _onUserAuthenticated(AppUser user) async {
    state = state.copyWith(
      user: user,
      status: SyncStatus.syncing,
      clearError: true,
    );
    _startPeriodicSync();
    await _performTwoWaySync();
  }

  /// Sign in with email and password, with optional 2FA verification.
  Future<bool> signInWithEmail(
    String email,
    String password, {
    String? twoFactorCode,
  }) async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInWithEmail(
        email,
        password,
        twoFactorCode: twoFactorCode,
      );
      await _onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign up with email and password, with optional 2FA code setup.
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
    String? twoFactorCode,
  }) async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signUpWithEmail(
        email,
        password,
        displayName: displayName,
        twoFactorCode: twoFactorCode,
      );
      await _onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Real Google SSO authentication via system browser & Google Identity Services.
  Future<bool> signInWithGoogleSso() async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final ssoService = GoogleSsoService();
      final result = await ssoService.signIn(clientId: state.config.oAuthClientId);
      if (result.isCancelled) {
        state = state.copyWith(
          status: state.user != null ? SyncStatus.synced : SyncStatus.guest,
          clearError: true,
        );
        return false;
      }
      if (!result.isSuccess) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: result.errorMessage ?? 'Google SSO failed.',
        );
        return false;
      }
      final user = await authService.signInWithGoogleSso(result.idToken!);
      await _onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 1-Click Google Sign-In without passwords or registration.
  Future<bool> signInWithGoogle({
    String? email,
    String? displayName,
    String? idToken,
  }) async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInWithGoogle(
        googleEmail: email,
        displayName: displayName,
        idToken: idToken,
      );
      await _onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign in anonymously or in guest mode.
  Future<bool> signInAnonymously() async {
    if (!state.config.isConfigured) {
      // Offline mock/demo guest sign-in when no Firebase credentials
      final mockUser = AppUser(
        uid: 'demo-guest-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Explorer',
        isAnonymous: true,
      );
      state = state.copyWith(
        user: mockUser,
        status: SyncStatus.synced,
        lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    }

    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInAnonymously();
      await _onUserAuthenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Signs out the user and switches back to guest mode.
  Future<void> signOut() async {
    _debounceTimer?.cancel();
    _stopPeriodicSync();
    await authService.signOut();
    state = state.copyWith(
      clearUser: true,
      status: SyncStatus.guest,
      clearError: true,
    );
  }

  /// Updates the user's real / display name across local session and Cloud Firestore.
  Future<void> updateDisplayName(String newName) async {
    final user = state.user;
    if (user == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final updated = user.copyWith(displayName: trimmed);
    await authService.updateUserProfile(updated);
    state = state.copyWith(user: updated);
  }

  /// Deletes user board from Firestore, user profile doc, and auth account.
  Future<bool> deleteAccountAndCloudData() async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(status: SyncStatus.syncing);
    try {
      _stopPeriodicSync();
      await firestoreService.deleteBoard(userId: user.uid, idToken: user.idToken);
      await authService.deleteUserAccount(user);
      state = state.copyWith(
        clearUser: true,
        status: SyncStatus.guest,
        syncedTaskCount: 0,
        lastSyncedAt: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: 'Failed to delete account data: ${e.toString()}',
      );
      return false;
    }
  }

  /// Updates daily check-in energy data and schedules cloud sync if signed in.
  Future<void> updateDailyCheckin(DailyCheckin checkin) async {
    state = state.copyWith(dailyCheckin: checkin);
    if (state.user != null) {
      final tasks = _ref.read(taskStateProvider).tasks;
      _handleLocalTasksChanged(tasks);
    }
  }

  /// Updates Firebase configuration credentials.
  Future<void> updateConfig(FirebaseConfig newConfig) async {
    await newConfig.save();
    authService.config = newConfig;
    firestoreService.config = newConfig;
    state = state.copyWith(config: newConfig);
  }
}

// Riverpod Providers for Firebase & Sync

final firebaseConfigProvider = FutureProvider<FirebaseConfig>((ref) async {
  return await FirebaseConfig.load();
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  final config = ref.watch(syncControllerProvider.select((s) => s.config));
  return FirebaseAuthService(config: config);
});

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final config = ref.watch(syncControllerProvider.select((s) => s.config));
  return FirestoreSyncService(config: config);
});

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  // Start with an empty config (isConfigured = false, configLoaded = false).
  // The real persisted credentials are loaded inside SyncController._init()
  // via await, which runs before any user interaction is possible. This
  // eliminates the race condition that caused "Firebase is not configured"
  // errors on real devices with slow SharedPreferences I/O.
  const initialConfig = FirebaseConfig();
  final authService = FirebaseAuthService(config: initialConfig);
  final firestoreService = FirestoreSyncService(config: initialConfig);

  return SyncController(
    ref: ref,
    authService: authService,
    firestoreService: firestoreService,
    initialConfig: initialConfig,
  );
});
