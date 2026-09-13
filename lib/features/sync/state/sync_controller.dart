import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../model/app_user.dart';
import '../model/daily_checkin.dart';
import '../model/sync_status.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_config.dart';
import '../services/firestore_sync_service.dart';

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
class SyncController extends StateNotifier<SyncState> {
  final Ref _ref;
  final FirebaseAuthService authService;
  final FirestoreSyncService firestoreService;
  Timer? _debounceTimer;

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

    // 3. Hydrate cached session if exists
    final cachedUser = await FirebaseAuthService.loadCachedUser();
    if (cachedUser != null && state.user == null) {
      await _onUserAuthenticated(cachedUser);
    }
  }

  /// Returns true if config is loaded; otherwise sets an error and returns false.
  bool _guardConfigLoaded() {
    if (!state.configLoaded) {
      state = state.copyWith(
        errorMessage: 'Connecting to Firebase… please try again in a moment.',
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

    // Debounce the cloud write by exactly 1,000 milliseconds
    _debounceTimer?.cancel();
    state = state.copyWith(isDebouncing: true);

    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      await _executeCloudSync(tasks);
    });
  }

  /// Executes the actual write to Cloud Firestore at `/users/{userId}/meta/board`.
  Future<void> _executeCloudSync(List<PinTask> tasks) async {
    final user = state.user;
    if (user == null) return;

    state = state.copyWith(
      status: SyncStatus.syncing,
      isDebouncing: false,
      clearError: true,
    );

    final taskMaps = tasks.map((t) => t.toJson()).toList();
    final checkinMap = state.dailyCheckin?.toJson();

    final result = await firestoreService.syncBoardToFirestore(
      userId: user.uid,
      idToken: user.idToken,
      tasks: taskMaps,
      dailyCheckin: checkinMap,
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
  }

  /// Forces an immediate cloud sync, cancelling any pending debounce timer.
  Future<void> syncNow() async {
    _debounceTimer?.cancel();
    final tasks = _ref.read(taskStateProvider).tasks;
    await _executeCloudSync(tasks);
  }

  /// Called when a user successfully authenticates. Coordinates cloud hydration.
  Future<void> _onUserAuthenticated(AppUser user) async {
    state = state.copyWith(
      user: user,
      status: SyncStatus.syncing,
      clearError: true,
    );

    try {
      // 1. Load board from Cloud Firestore
      final cloudBoard = await firestoreService.loadBoardFromFirestore(
        userId: user.uid,
        idToken: user.idToken,
      );

      final taskNotifier = _ref.read(taskStateProvider.notifier);

      if (cloudBoard != null && cloudBoard.tasks.isNotEmpty) {
        // Cloud has tasks: hydrate board from cloud
        final cloudTasks = cloudBoard.tasks.map((m) => PinTask.fromJson(m)).toList();
        await taskNotifier.hydrateFromCloud(cloudTasks);

        DailyCheckin? checkin;
        if (cloudBoard.dailyCheckin != null && cloudBoard.dailyCheckin!.isNotEmpty) {
          checkin = DailyCheckin.fromJson(cloudBoard.dailyCheckin!);
        }

        state = state.copyWith(
          user: user,
          status: SyncStatus.synced,
          lastSyncedAt: cloudBoard.lastSyncedAt,
          dailyCheckin: checkin,
          syncedTaskCount: cloudTasks.length,
        );
      } else {
        // New account or empty cloud board: seed cloud with existing local tasks
        final currentLocalTasks = _ref.read(taskStateProvider).tasks;
        await _executeCloudSync(currentLocalTasks);
      }
    } catch (e) {
      state = state.copyWith(
        user: user,
        status: SyncStatus.error,
        errorMessage: 'Failed to hydrate from cloud: ${e.toString()}',
      );
    }
  }

  /// Sign in with email and password.
  Future<bool> signInWithEmail(String email, String password) async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInWithEmail(email, password);
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

  /// Sign up with email and password.
  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signUpWithEmail(email, password, displayName: displayName);
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
  Future<bool> signInWithGoogle({String? email, String? displayName}) async {
    if (!_guardConfigLoaded()) return false;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final user = await authService.signInWithGoogle(
        googleEmail: email,
        displayName: displayName,
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
