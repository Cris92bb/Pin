/// State of Cloud Firestore synchronization.
enum SyncStatus {
  /// User is not logged in; local storage operates independently.
  guest,

  /// Cloud write or read is currently in progress.
  syncing,

  /// Board state is completely in sync with Cloud Firestore.
  synced,

  /// Device is offline or network request timed out.
  offline,

  /// An error occurred during cloud synchronization.
  error;

  String get label {
    switch (this) {
      case SyncStatus.guest:
        return 'Guest (Local)';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }
}
