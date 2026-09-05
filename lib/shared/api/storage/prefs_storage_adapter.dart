import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_adapter.dart';

/// Cross-platform storage adapter backed by SharedPreferences.
///
/// Guaranteed to work consistently on Web (localStorage),
/// Android (SharedPreferences), iOS (NSUserDefaults), and Desktop.
class PrefsStorageAdapter implements StorageAdapter {
  static const String _key = 'pin_tasks_v1';
  final SharedPreferences? _customPrefs;

  PrefsStorageAdapter({SharedPreferences? customPrefs})
      : _customPrefs = customPrefs;

  Future<SharedPreferences> _getPrefs() async {
    return _customPrefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<Map<String, dynamic>>> loadTasks() async {
    try {
      final prefs = await _getPrefs();
      final content = prefs.getString(_key);
      if (content == null || content.trim().isEmpty) {
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
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final prefs = await _getPrefs();
      final payload = {
        'app': 'pin',
        'version': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'count': tasks.length,
        'tasks': tasks,
      };
      final jsonStr = jsonEncode(payload);
      await prefs.setString(_key, jsonStr);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove(_key);
  }
}
