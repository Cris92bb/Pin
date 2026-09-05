import 'dart:convert';

/// Codec to encode and decode Pin tasks into portable JSON/Base64 blueprints
/// for instant sharing across devices without any external network dependency.
class BlueprintCodec {
  static const int currentVersion = 1;
  static const String prefix = 'PIN_BP_';

  /// Encodes a list of task maps into a compact Base64 blueprint string.
  static String encodeTasks(List<Map<String, dynamic>> taskJsonList) {
    final payload = {
      'app': 'pin',
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'count': taskJsonList.length,
      'tasks': taskJsonList,
    };
    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    final b64 = base64Url.encode(bytes);
    return '$prefix$b64';
  }

  /// Encodes a single task into a blueprint string.
  static String encodeSingleTask(Map<String, dynamic> taskJson) {
    return encodeTasks([taskJson]);
  }

  /// Decodes either a Base64 blueprint string (with or without 'PIN_BP_')
  /// or raw JSON string into a list of task maps.
  static BlueprintDecodeResult decode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const BlueprintDecodeResult.error('Input blueprint is empty');
    }

    try {
      String jsonStr;
      if (trimmed.startsWith(prefix)) {
        final b64 = trimmed.substring(prefix.length);
        final bytes = base64Url.decode(base64Url.normalize(b64));
        jsonStr = utf8.decode(bytes);
      } else if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        jsonStr = trimmed;
      } else {
        // Attempt base64 decode directly
        try {
          final bytes = base64Url.decode(base64Url.normalize(trimmed));
          jsonStr = utf8.decode(bytes);
        } catch (_) {
          return const BlueprintDecodeResult.error('Unrecognized blueprint format');
        }
      }

      final dynamic parsed = jsonDecode(jsonStr);
      if (parsed is List) {
        final tasks = parsed.whereType<Map<String, dynamic>>().toList();
        return BlueprintDecodeResult.success(
          tasks: tasks,
          version: 1,
          count: tasks.length,
        );
      } else if (parsed is Map<String, dynamic>) {
        final tasksRaw = parsed['tasks'];
        if (tasksRaw is List) {
          final tasks = tasksRaw
              .whereType<Map<String, dynamic>>()
              .toList();
          return BlueprintDecodeResult.success(
            tasks: tasks,
            version: (parsed['version'] as num?)?.toInt() ?? 1,
            exportedAt: parsed['exportedAt'] as String?,
            count: tasks.length,
          );
        } else if (parsed.containsKey('title') && parsed.containsKey('id')) {
          // Single task object
          return BlueprintDecodeResult.success(
            tasks: [parsed],
            version: 1,
            count: 1,
          );
        }
      }
      return const BlueprintDecodeResult.error('Blueprint payload does not contain valid task items');
    } catch (e) {
      return BlueprintDecodeResult.error('Failed to parse blueprint: ${e.toString()}');
    }
  }
}

class BlueprintDecodeResult {
  final bool isSuccess;
  final List<Map<String, dynamic>> tasks;
  final int version;
  final String? exportedAt;
  final int count;
  final String? errorMessage;

  const BlueprintDecodeResult.success({
    required this.tasks,
    required this.version,
    this.exportedAt,
    required this.count,
  })  : isSuccess = true,
        errorMessage = null;

  const BlueprintDecodeResult.error(this.errorMessage)
      : isSuccess = false,
        tasks = const [],
        version = 1,
        exportedAt = null,
        count = 0;
}
