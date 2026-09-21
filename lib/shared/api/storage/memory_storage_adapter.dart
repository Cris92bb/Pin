import 'storage_adapter.dart';

/// In-memory storage adapter for fast unit tests and stateless runs.
class MemoryStorageAdapter implements StorageAdapter {
  List<Map<String, dynamic>> _storage;
  List<Map<String, dynamic>> _boardsStorage;

  MemoryStorageAdapter([
    List<Map<String, dynamic>>? initialTasks,
    List<Map<String, dynamic>>? initialBoards,
  ])  : _storage = initialTasks != null ? List.from(initialTasks) : [],
        _boardsStorage = initialBoards != null ? List.from(initialBoards) : [];

  @override
  Future<List<Map<String, dynamic>>> loadTasks() async {
    return List.from(_storage);
  }

  @override
  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    _storage = List.from(tasks);
  }

  @override
  Future<List<Map<String, dynamic>>> loadBoards() async {
    return List.from(_boardsStorage);
  }

  @override
  Future<void> saveBoards(List<Map<String, dynamic>> boards) async {
    _boardsStorage = List.from(boards);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
    _boardsStorage.clear();
    _multiBoardEnabled = false;
  }

  bool _multiBoardEnabled = false;

  @override
  Future<bool> isMultiBoardEnabled() async => _multiBoardEnabled;

  @override
  Future<void> setMultiBoardEnabled(bool enabled) async {
    _multiBoardEnabled = enabled;
  }
}
