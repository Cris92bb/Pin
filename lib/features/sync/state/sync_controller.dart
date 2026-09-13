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

    // 3. Hydrate cached session if exists
    final cachedUser = await FirebaseAuthService.loadCachedUser();
    if (cachedUser != null && state.user == null) {
      await _onUserAuthenticated(cachedUser);
    }
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
    var user = state.user;
    if (user == null) return;

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
        // Refresh failed (e.g. revoked refresh token) — sign the user out so
        // they get a clean prompt to re-authenticate rather than a silent loop.
        await signOut();
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Session expired. Please sign in again.',
        );
        return;
      }
    }

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

  /// Called when a user successfully authenticates. Coordinates cloud hydration
  /// using a **three-way merge** so neither device silently loses its tasks.
  ///
  /// Merge rules (per task ID):
  ///   1. Task exists on both sides → keep the version with the later [updatedAt].
  ///   2. Task only in cloud       → add it (created on another device).
  ///   3. Task only in local       → keep it (not yet synced to cloud).
  ///
  /// After merging the unified list is immediately pushed to Firestore so every
  /// device that signs in next will see the correct merged state.
  Future<void> _onUserAuthenticated(AppUser user) async {
    state = state.copyWith(
      user: user,
      status: SyncStatus.syncing,
      clearError: true,
    );

    try {
      // 1. Fetch cloud snapshot.
      final cloudBoard = await firestoreService.loadBoardFromFirestore(
        userId: user.uid,
        idToken: user.idToken,
      );

      final taskNotifier = _ref.read(taskStateProvider.notifier);
      final localTasks = _ref.read(taskStateProvider).tasks;

      if (cloudBoard == null || cloudBoard.tasks.isEmpty) {
        // New account or empty cloud — seed cloud with local tasks.
        await _executeCloudSync(localTasks);
        state = state.copyWith(
          user: user,
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
          syncedTaskCount: localTasks.length,
        );
        return;
      }

      // 2. Parse cloud tasks.
      final cloudTasks = cloudBoard.tasks
          .map((m) => PinTask.fromJson(m))
          .toList();

      // 3. Merge: build a map keyed by task ID, starting from local.
      final Map<String, PinTask> merged = {
        for (final t in localTasks) t.id: t,
      };

      // For each cloud task: if the same ID already exists locally, keep
      // whichever was updated more recently; otherwise add the cloud task.
      for (final cloudTask in cloudTasks) {
        final local = merged[cloudTask.id];
        if (local == null) {
          // Task exists only in cloud (created on another device) → add it.
          merged[cloudTask.id] = cloudTask;
        } else if (cloudTask.updatedAt.isAfter(local.updatedAt)) {
          // Cloud version is newer → prefer cloud.
          merged[cloudTask.id] = cloudTask;
        }
        // else: local version is newer or equal → keep local (already in map).
      }

      final mergedList = merged.values.toList();

      // 4. Apply merged list to local storage.
      await taskNotifier.hydrateFromCloud(mergedList);

      // 5. Restore daily check-in from cloud if available.
      DailyCheckin? checkin;
      if (cloudBoard.dailyCheckin != null &&
          cloudBoard.dailyCheckin!.isNotEmpty) {
        checkin = DailyCheckin.fromJson(cloudBoard.dailyCheckin!);
      }

      state = state.copyWith(
        user: user,
        status: SyncStatus.synced,
        lastSyncedAt: cloudBoard.lastSyncedAt,
        dailyCheckin: checkin,
        syncedTaskCount: mergedList.length,
      );

      // 6. Push the merged result back to Firestore immediately so the next
      //    device that signs in gets the unified set.
      await _executeCloudSync(mergedList);

    } catch (e) {
      state = state.copyWith(
        user: user,
        status: SyncStatus.error,
        errorMessage: 'Sync merge failed: ${e.toString()}',
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
