import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase credentials and project identifiers.
class FirebaseConfig {
  static const String _keyApiKey = 'firebase_api_key';
  static const String _keyProjectId = 'firebase_project_id';
  static const String _keyAuthDomain = 'firebase_auth_domain';
  static const String _keyDatabaseId = 'firebase_database_id';
  static const String _keyStorageBucket = 'firebase_storage_bucket';
  static const String _keyOAuthClientId = 'firebase_oauth_client_id';

  final String apiKey;
  final String projectId;
  final String authDomain;
  final String firestoreDatabaseId;
  final String storageBucket;
  final String oAuthClientId;

  const FirebaseConfig({
    this.apiKey = '',
    this.projectId = '',
    this.authDomain = '',
    this.firestoreDatabaseId = '(default)',
    this.storageBucket = '',
    this.oAuthClientId = '',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty && projectId.trim().isNotEmpty;

  FirebaseConfig copyWith({
    String? apiKey,
    String? projectId,
    String? authDomain,
    String? firestoreDatabaseId,
    String? storageBucket,
    String? oAuthClientId,
  }) {
    return FirebaseConfig(
      apiKey: apiKey ?? this.apiKey,
      projectId: projectId ?? this.projectId,
      authDomain: authDomain ?? this.authDomain,
      firestoreDatabaseId: firestoreDatabaseId ?? this.firestoreDatabaseId,
      storageBucket: storageBucket ?? this.storageBucket,
      oAuthClientId: oAuthClientId ?? this.oAuthClientId,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'projectId': projectId,
        'authDomain': authDomain,
        'firestoreDatabaseId': firestoreDatabaseId,
        'storageBucket': storageBucket,
        'oAuthClientId': oAuthClientId,
      };

  factory FirebaseConfig.fromJson(Map<String, dynamic> json) => FirebaseConfig(
        apiKey: json['apiKey'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        authDomain: json['authDomain'] as String? ?? '',
        firestoreDatabaseId: json['firestoreDatabaseId'] as String? ?? '(default)',
        storageBucket: json['storageBucket'] as String? ?? '',
        oAuthClientId: json['oAuthClientId'] as String? ?? '',
      );

  /// Loads Firebase configuration.
  ///
  /// Loading priority:
  ///   1. Bundled Flutter asset `firebase-applet-config.json` — works on
  ///      Android, iOS, and packaged desktop builds.
  ///   2. `File('firebase-applet-config.json')` relative to the process CWD —
  ///      works on Linux/macOS/Windows desktop during `flutter run` development
  ///      where the project root is the working directory.
  ///   3. Persisted [SharedPreferences] credentials entered by the user in the
  ///      Cloud Sync settings panel.
  static Future<FirebaseConfig> load() async {
    // 1. Flutter asset bundle (mobile & packaged desktop).
    try {
      final content = await rootBundle.loadString('firebase-applet-config.json');
      final json = jsonDecode(content) as Map<String, dynamic>;
      final fileConfig = FirebaseConfig.fromJson(json);
      if (fileConfig.isConfigured) return fileConfig;
    } catch (_) {}

    // 2. Filesystem file relative to CWD (desktop development via flutter run).
    try {
      final file = File('firebase-applet-config.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final fileConfig = FirebaseConfig.fromJson(json);
        if (fileConfig.isConfigured) return fileConfig;
      }
    } catch (_) {}

    // 3. Persisted SharedPreferences credentials (user-entered via settings).
    return loadFromPreferences();
  }

  /// Loads credentials persisted in SharedPreferences.
  static Future<FirebaseConfig> loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(_keyApiKey) ?? '';
      final projectId = prefs.getString(_keyProjectId) ?? '';
      final authDomain = prefs.getString(_keyAuthDomain) ?? '';
      final dbId = prefs.getString(_keyDatabaseId) ?? '(default)';
      final storageBucket = prefs.getString(_keyStorageBucket) ?? '';
      final oAuthClientId = prefs.getString(_keyOAuthClientId) ?? '';
      return FirebaseConfig(
        apiKey: apiKey,
        projectId: projectId,
        authDomain: authDomain,
        firestoreDatabaseId: dbId,
        storageBucket: storageBucket,
        oAuthClientId: oAuthClientId,
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
      await prefs.setString(_keyStorageBucket, storageBucket.trim());
      await prefs.setString(_keyOAuthClientId, oAuthClientId.trim());
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiKey);
      await prefs.remove(_keyProjectId);
      await prefs.remove(_keyAuthDomain);
      await prefs.remove(_keyDatabaseId);
      await prefs.remove(_keyStorageBucket);
      await prefs.remove(_keyOAuthClientId);
    } catch (_) {}
  }
}
