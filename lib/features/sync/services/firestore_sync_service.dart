import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_config.dart';
import 'firestore_rest_codec.dart';

/// Result of a cloud board synchronization operation.
class SyncResult {
  final bool success;
  final int syncedAt;
  final int count;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    required this.syncedAt,
    required this.count,
    this.errorMessage,
  });
}

/// Payload returned when hydrating board from Firestore.
class CloudBoardData {
  final List<Map<String, dynamic>> tasks;
  final Map<String, dynamic>? dailyCheckin;
  final int lastSyncedAt;
  final int count;

  const CloudBoardData({
    required this.tasks,
    this.dailyCheckin,
    required this.lastSyncedAt,
    required this.count,
  });
}

/// Service that executes Firestore REST API operations for the board snapshot document
/// located at `/users/{userId}/meta/board`.
class FirestoreSyncService {
  final http.Client _client;
  FirebaseConfig config;

  FirestoreSyncService({
    http.Client? client,
    required this.config,
  }) : _client = client ?? http.Client();

  Uri _buildBoardDocUri(String userId) {
    final dbId = config.firestoreDatabaseId.isEmpty ? '(default)' : config.firestoreDatabaseId;
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/$dbId/documents/users/$userId/meta/board',
    );
  }

  Map<String, String> _buildHeaders(String? idToken) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }
    return headers;
  }

  /// Pushes the complete board state to Cloud Firestore at `/users/{userId}/meta/board`.
  Future<SyncResult> syncBoardToFirestore({
    required String userId,
    String? idToken,
    required List<Map<String, dynamic>> tasks,
    Map<String, dynamic>? dailyCheckin,
  }) async {
    if (!config.isConfigured) {
      return SyncResult(
        success: false,
        syncedAt: DateTime.now().millisecondsSinceEpoch,
        count: tasks.length,
        errorMessage: 'Firebase credentials are not configured.',
      );
    }

    final syncedAt = DateTime.now().millisecondsSinceEpoch;

    if (idToken == null || idToken.isEmpty) {
      return SyncResult(
        success: false,
        syncedAt: syncedAt,
        count: tasks.length,
        errorMessage: 'Cannot sync with Cloud Firestore: Missing authentication token. Please sign in to Firebase to sync.',
      );
    }

    final boardDocUri = _buildBoardDocUri(userId);

    final fields = FirestoreRestCodec.encodeFields({
      'tasks': tasks,
      'dailyCheckin': dailyCheckin ?? {},
      'lastSyncedAt': syncedAt,
      'count': tasks.length,
    });

    try {
      final response = await _client.patch(
        boardDocUri,
        headers: _buildHeaders(idToken),
        body: jsonEncode({'fields': fields}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SyncResult(
          success: true,
          syncedAt: syncedAt,
          count: tasks.length,
        );
      } else {
        return SyncResult(
          success: false,
          syncedAt: syncedAt,
          count: tasks.length,
          errorMessage: 'Sync failed (HTTP ${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        syncedAt: syncedAt,
        count: tasks.length,
        errorMessage: e.toString(),
      );
    }
  }

  /// Loads the cloud board snapshot from `/users/{userId}/meta/board`.
  Future<CloudBoardData?> loadBoardFromFirestore({
    required String userId,
    String? idToken,
  }) async {
    if (!config.isConfigured) return null;

    final boardDocUri = _buildBoardDocUri(userId);
    try {
      final response = await _client.get(
        boardDocUri,
        headers: _buildHeaders(idToken),
      );

      if (response.statusCode == 404) {
        // Document does not exist yet (new account)
        return null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawFields = data['fields'] as Map<String, dynamic>? ?? {};
        final decoded = FirestoreRestCodec.decodeFields(rawFields);

        final rawTasks = decoded['tasks'] as List<dynamic>? ?? [];
        final taskMaps = rawTasks
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();

        final rawCheckin = decoded['dailyCheckin'];
        final checkinMap = rawCheckin is Map ? Map<String, dynamic>.from(rawCheckin) : null;
        final lastSyncedAt = (decoded['lastSyncedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
        final count = (decoded['count'] as num?)?.toInt() ?? taskMaps.length;

        return CloudBoardData(
          tasks: taskMaps,
          dailyCheckin: checkinMap,
          lastSyncedAt: lastSyncedAt,
          count: count,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Deletes the board document from `/users/{userId}/meta/board`.
  Future<bool> deleteBoard({
    required String userId,
    String? idToken,
  }) async {
    if (!config.isConfigured) return false;
    final boardDocUri = _buildBoardDocUri(userId);
    try {
      final response = await _client.delete(
        boardDocUri,
        headers: _buildHeaders(idToken),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
