/// Abstract contract for local task persistence in Pin.
abstract class StorageAdapter {
  /// Loads all saved task maps from persistent storage.
  Future<List<Map<String, dynamic>>> loadTasks();

  /// Persists task maps to storage.
  Future<void> saveTasks(List<Map<String, dynamic>> tasks);

  /// Clears all stored tasks.
  Future<void> clear();
}
