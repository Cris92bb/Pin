import 'storage_adapter.dart';

/// In-memory storage adapter for fast unit tests and stateless runs.
class MemoryStorageAdapter implements StorageAdapter {
  List<Map<String, dynamic>> _storage;

  MemoryStorageAdapter([List<Map<String, dynamic>>? initialTasks])
      : _storage = initialTasks != null ? List.from(initialTasks) : [];

  @override
  Future<List<Map<String, dynamic>>> loadTasks() async {
    return List.from(_storage);
  }

  @override
  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    _storage = List.from(tasks);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
