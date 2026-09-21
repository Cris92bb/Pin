import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs_storage_adapter.dart';

/// Abstract contract for local task persistence in Pin.
abstract class StorageAdapter {
  /// Loads all saved task maps from persistent storage.
  Future<List<Map<String, dynamic>>> loadTasks();

  /// Persists task maps to storage.
  Future<void> saveTasks(List<Map<String, dynamic>> tasks);

  /// Loads all saved board maps from persistent storage.
  Future<List<Map<String, dynamic>>> loadBoards() async => [];

  /// Persists board maps to storage.
  Future<void> saveBoards(List<Map<String, dynamic>> boards) async {}

  /// Clears all stored tasks.
  Future<void> clear();

  /// Checks whether multi-board workspaces feature toggle is enabled.
  Future<bool> isMultiBoardEnabled() async => false;

  /// Sets whether multi-board workspaces feature toggle is enabled.
  Future<void> setMultiBoardEnabled(bool enabled) async {}
}

/// Active storage adapter provider supplying persistent task storage.
final storageAdapterProvider = Provider<StorageAdapter>((ref) {
  return PrefsStorageAdapter();
});
