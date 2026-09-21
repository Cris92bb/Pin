import 'dart:convert';
import 'dart:io';
import 'storage_adapter.dart';

/// Local JSON file storage adapter for Pin on Linux desktop.
///
/// Stores task models in `~/.local/share/pin/pin_tasks.json` with
/// atomic swap operations (.tmp -> rename) to guarantee zero file corruption.
class LocalFileStorageAdapter implements StorageAdapter {
  final File file;

  LocalFileStorageAdapter({File? customFile})
      : file = customFile ?? _resolveDefaultFile();

  static File _resolveDefaultFile() {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final dir = Directory('$home/.local/share/pin');
      return File('${dir.path}/pin_tasks.json');
    }
    return File('.pin_tasks.json');
  }

  @override
  Future<List<Map<String, dynamic>>> loadTasks() async {
    try {
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      } else if (decoded is Map<String, dynamic> && decoded['tasks'] is List) {
        final list = decoded['tasks'] as List;
        return list.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      // If reading fails or file is corrupted, preserve corrupted copy and return empty
      try {
        final backup = File('${file.path}.corrupt.${DateTime.now().millisecondsSinceEpoch}');
        if (await file.exists()) {
          await file.copy(backup.path);
        }
      } catch (_) {}
      return [];
    }
  }

  @override
  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final payload = {
        'app': 'pin',
        'version': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'count': tasks.length,
        'tasks': tasks,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(jsonStr, flush: true);
      await tmpFile.rename(file.path);
    } catch (e) {
      // Re-throw or handle gracefully
      rethrow;
    }
  }

  File get _boardsFile => File('${file.parent.path}/pin_boards.json');

  @override
  Future<List<Map<String, dynamic>>> loadBoards() async {
    try {
      final bFile = _boardsFile;
      if (!await bFile.exists()) return [];
      final content = await bFile.readAsString();
      if (content.trim().isEmpty) return [];
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      } else if (decoded is Map<String, dynamic> && decoded['boards'] is List) {
        return (decoded['boards'] as List).whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveBoards(List<Map<String, dynamic>> boards) async {
    try {
      final bFile = _boardsFile;
      final parentDir = bFile.parent;
      if (!await parentDir.exists()) await parentDir.create(recursive: true);
      final payload = {
        'app': 'pin',
        'version': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'count': boards.length,
        'boards': boards,
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final tmpFile = File('${bFile.path}.tmp');
      await tmpFile.writeAsString(jsonStr, flush: true);
      await tmpFile.rename(bFile.path);
    } catch (_) {}
  }

  bool _multiBoardEnabled = false;

  @override
  Future<bool> isMultiBoardEnabled() async => _multiBoardEnabled;

  @override
  Future<void> setMultiBoardEnabled(bool enabled) async {
    _multiBoardEnabled = enabled;
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
    if (await _boardsFile.exists()) {
      await _boardsFile.delete();
    }
    _multiBoardEnabled = false;
  }
}
