import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs_storage_adapter.dart';

/// Abstract contract for local task persistence in Pin.
abstract class StorageAdapter {
  /// Loads all saved task maps from persistent storage.
  Future<List<Map<String, dynamic>>> loadTasks();

  /// Persists task maps to storage.
  Future<void> saveTasks(List<Map<String, dynamic>> tasks);

  /// Clears all stored tasks.
  Future<void> clear();
}

/// Active storage adapter provider supplying persistent task storage.
final storageAdapterProvider = Provider<StorageAdapter>((ref) {
  return PrefsStorageAdapter();
});
