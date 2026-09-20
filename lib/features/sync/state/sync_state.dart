import '../model/app_user.dart';
import '../model/daily_checkin.dart';
import '../model/sync_status.dart';
import '../services/firebase_config.dart';

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
