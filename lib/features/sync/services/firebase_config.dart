import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase credentials and project identifiers.
class FirebaseConfig {
  static const String _keyApiKey = 'firebase_api_key';
  static const String _keyProjectId = 'firebase_project_id';
  static const String _keyAuthDomain = 'firebase_auth_domain';
  static const String _keyDatabaseId = 'firebase_database_id';

  final String apiKey;
  final String projectId;
  final String authDomain;
  final String firestoreDatabaseId;

  const FirebaseConfig({
    this.apiKey = '',
    this.projectId = '',
    this.authDomain = '',
    this.firestoreDatabaseId = '(default)',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty && projectId.trim().isNotEmpty;

  FirebaseConfig copyWith({
    String? apiKey,
    String? projectId,
    String? authDomain,
    String? firestoreDatabaseId,
  }) {
    return FirebaseConfig(
      apiKey: apiKey ?? this.apiKey,
      projectId: projectId ?? this.projectId,
      authDomain: authDomain ?? this.authDomain,
      firestoreDatabaseId: firestoreDatabaseId ?? this.firestoreDatabaseId,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'projectId': projectId,
        'authDomain': authDomain,
        'firestoreDatabaseId': firestoreDatabaseId,
      };

  factory FirebaseConfig.fromJson(Map<String, dynamic> json) => FirebaseConfig(
        apiKey: json['apiKey'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        authDomain: json['authDomain'] as String? ?? '',
        firestoreDatabaseId: json['firestoreDatabaseId'] as String? ?? '(default)',
      );

  static Future<FirebaseConfig> load() async {
    // 1. Check if firebase-applet-config.json exists on disk
    try {
      final file = File('firebase-applet-config.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final fileConfig = FirebaseConfig.fromJson(json);
        if (fileConfig.isConfigured) {
          return fileConfig;
        }
      }
    } catch (_) {}

    // 2. Fallback to persisted SharedPreferences credentials
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(_keyApiKey) ?? '';
      final projectId = prefs.getString(_keyProjectId) ?? '';
      final authDomain = prefs.getString(_keyAuthDomain) ?? '';
      final dbId = prefs.getString(_keyDatabaseId) ?? '(default)';
      return FirebaseConfig(
        apiKey: apiKey,
        projectId: projectId,
        authDomain: authDomain,
        firestoreDatabaseId: dbId,
      );
    } catch (_) {
      return const FirebaseConfig();
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyApiKey, apiKey.trim());
      await prefs.setString(_keyProjectId, projectId.trim());
      await prefs.setString(_keyAuthDomain, authDomain.trim());
      await prefs.setString(_keyDatabaseId, firestoreDatabaseId.trim().isEmpty ? '(default)' : firestoreDatabaseId.trim());
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiKey);
      await prefs.remove(_keyProjectId);
      await prefs.remove(_keyAuthDomain);
      await prefs.remove(_keyDatabaseId);
    } catch (_) {}
  }
}
