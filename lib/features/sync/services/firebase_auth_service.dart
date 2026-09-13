import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_user.dart';
import 'firebase_config.dart';
import 'firestore_rest_codec.dart';

/// Service handling Firebase Authentication via Google Identity Toolkit REST API
/// and managing the user profile document in Cloud Firestore.
class FirebaseAuthService {
  static const String _keyStoredUser = 'firebase_cached_user';
  final http.Client _client;
  FirebaseConfig config;

  FirebaseAuthService({
    http.Client? client,
    required this.config,
  }) : _client = client ?? http.Client();

  /// Loads cached session from local storage.
  static Future<AppUser?> loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyStoredUser);
      if (raw != null && raw.isNotEmpty) {
        final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        // Purge legacy/broken sessions without an ID token
        if (user.idToken == null || user.idToken!.isEmpty) {
          await prefs.remove(_keyStoredUser);
          return null;
        }
        return user;
      }
    } catch (_) {}
    return null;
  }

  /// Persists cached session locally.
  Future<void> _saveCachedUser(AppUser? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove(_keyStoredUser);
      } else {
        await prefs.setString(_keyStoredUser, jsonEncode(user.toJson()));
      }
    } catch (_) {}
  }

  /// Signs in anonymously using Firebase Auth.
  Future<AppUser> signInAnonymously() async {
    _ensureConfigured();
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${config.apiKey}',
    );

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'returnSecureToken': true}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn =
          int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
      final user = AppUser(
        uid: data['localId'] as String,
        idToken: data['idToken'] as String?,
        refreshToken: data['refreshToken'] as String?,
        tokenExpiresAt: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch,
        isAnonymous: true,
      );
      await _syncUserProfile(user);
      await _saveCachedUser(user);
      return user;
    } else {
      final error = _parseError(response.body);
      throw Exception('Firebase Anonymous Sign-In failed: $error');
    }
  }

  /// 1-Click Google Sign-In without passwords or registration.
  ///
  /// Uses a deterministic, email-derived UID (`google_$sanitizedEmail`) across
  /// all environments and devices so desktop and mobile always read and write
  /// to the exact same Firestore document path (`/users/{uid}/...`).
  Future<AppUser> signInWithGoogle({
    String? googleEmail,
    String? displayName,
    String? idToken,
  }) async {
    // 1. If a real Google ID token was provided, use proper OAuth flow.
    if (idToken != null && idToken.isNotEmpty) {
      return await signInWithIdpToken(
          idToken: idToken, providerId: 'google.com');
    }

    final targetEmail = googleEmail?.trim().isNotEmpty == true
        ? googleEmail!.trim()
        : 'user@gmail.com';
    final targetName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : targetEmail.split('@').first;

    // Deterministic UID based strictly on the email
    final sanitizedEmail = targetEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final deterministicUid = 'google_$sanitizedEmail';

    // 2. Derive a stable pseudo-password from the email.
    final pseudoPassword =
        'Pin__${targetEmail.split('').reversed.join()}__Sync';

    if (config.isConfigured) {
      try {
        final url = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${config.apiKey}',
        );
        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': targetEmail,
            'password': pseudoPassword,
            'returnSecureToken': true,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final expiresIn =
              int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
          final user = AppUser(
            uid:
                deterministicUid, // <-- Override random Firebase UID with email-derived UID
            email: targetEmail,
            displayName: displayName?.trim().isNotEmpty == true
                ? displayName!.trim()
                : (data['displayName'] as String? ?? targetName),
            idToken: data['idToken'] as String?,
            refreshToken: data['refreshToken'] as String?,
            tokenExpiresAt: DateTime.now()
                .add(Duration(seconds: expiresIn))
                .millisecondsSinceEpoch,
            isAnonymous: false,
          );
          await _syncUserProfile(user);
          await _saveCachedUser(user);
          return user;
        }

        // Sign-in failed (e.g. EMAIL_NOT_FOUND) -> create account
        final signUpUrl = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${config.apiKey}',
        );
        final signUpResponse = await _client.post(
          signUpUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': targetEmail,
            'password': pseudoPassword,
            'returnSecureToken': true,
          }),
        );

        if (signUpResponse.statusCode >= 200 &&
            signUpResponse.statusCode < 300) {
          final data = jsonDecode(signUpResponse.body) as Map<String, dynamic>;
          final expiresIn =
              int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
          final user = AppUser(
            uid:
                deterministicUid, // <-- Override random Firebase UID with email-derived UID
            email: targetEmail,
            displayName: targetName,
            idToken: data['idToken'] as String?,
            refreshToken: data['refreshToken'] as String?,
            tokenExpiresAt: DateTime.now()
                .add(Duration(seconds: expiresIn))
                .millisecondsSinceEpoch,
            isAnonymous: false,
          );
          await _syncUserProfile(user);
          await _saveCachedUser(user);
          return user;
        }

        final error = _parseError(signUpResponse.body);
        throw Exception('Google Sign-In failed: $error');
      } catch (e) {
        final err = e.toString();
        if (err.contains('OPERATION_NOT_ALLOWED') ||
            err.contains('ADMIN_ONLY_OPERATION')) {
          throw Exception(
            'Email/Password auth is not enabled in your Firebase project. '
            'Go to Firebase Console → Authentication → Sign-in method and enable "Email/Password".',
          );
        }
        rethrow;
      }
    }

    // 3. Offline / fallback path
    final user = AppUser(
      uid: deterministicUid,
      email: targetEmail,
      displayName: targetName,
      photoURL: 'https://lh3.googleusercontent.com/a/default-user',
      isAnonymous: false,
    );
    await _saveCachedUser(user);
    return user;
  }

  /// Signs in with Email and Password.
  Future<AppUser> signInWithEmail(String email, String password) async {
    _ensureConfigured();
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${config.apiKey}',
    );

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn =
          int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
      final user = AppUser(
        uid: data['localId'] as String,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        idToken: data['idToken'] as String?,
        refreshToken: data['refreshToken'] as String?,
        tokenExpiresAt: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch,
        isAnonymous: false,
      );
      await _syncUserProfile(user);
      await _saveCachedUser(user);
      return user;
    } else {
      final error = _parseError(response.body);
      throw Exception('Firebase Sign-In failed: $error');
    }
  }

  /// Signs up with Email and Password.
  Future<AppUser> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    _ensureConfigured();
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${config.apiKey}',
    );

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn =
          int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
      final user = AppUser(
        uid: data['localId'] as String,
        email: data['email'] as String?,
        displayName: displayName ?? (data['displayName'] as String?),
        idToken: data['idToken'] as String?,
        refreshToken: data['refreshToken'] as String?,
        tokenExpiresAt: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch,
        isAnonymous: false,
      );
      await _syncUserProfile(user);
      await _saveCachedUser(user);
      return user;
    } else {
      final error = _parseError(response.body);
      throw Exception('Firebase Sign-Up failed: $error');
    }
  }

  /// Signs in using Google ID token or OAuth credential.
  Future<AppUser> signInWithIdpToken({
    required String idToken,
    required String providerId,
  }) async {
    _ensureConfigured();
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${config.apiKey}',
    );

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'postBody': 'id_token=$idToken&providerId=$providerId',
        'requestUri': 'http://localhost',
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn =
          int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
      final user = AppUser(
        uid: data['localId'] as String,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        photoURL: data['photoUrl'] as String?,
        idToken: data['idToken'] as String?,
        refreshToken: data['refreshToken'] as String?,
        tokenExpiresAt: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch,
        isAnonymous: false,
      );
      await _syncUserProfile(user);
      await _saveCachedUser(user);
      return user;
    } else {
      final error = _parseError(response.body);
      throw Exception('OAuth Sign-In failed: $error');
    }
  }

  /// Refreshes the Firebase ID token using the stored refresh token.
  ///
  /// Returns an updated [AppUser] with a new [idToken] and [tokenExpiresAt],
  /// or throws if the refresh token is missing or the request fails.
  Future<AppUser> refreshIdToken(AppUser user) async {
    _ensureConfigured();
    final refreshToken = user.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available — please sign in again.');
    }

    final url = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=${config.apiKey}',
    );
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'grant_type=refresh_token&refresh_token=$refreshToken',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final expiresIn =
          int.tryParse(data['expires_in']?.toString() ?? '3600') ?? 3600;
      final refreshed = user.copyWith(
        idToken: data['id_token'] as String?,
        refreshToken: data['refresh_token'] as String? ?? refreshToken,
        tokenExpiresAt: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch,
      );
      await _saveCachedUser(refreshed);
      return refreshed;
    } else {
      final error = _parseError(response.body);
      throw Exception('Token refresh failed: $error');
    }
  }

  /// Returns a fresh ID token for [user], automatically refreshing if expired.
  ///
  /// Callers should update their stored user with the returned [AppUser] since
  /// the token and its expiry may have changed.
  Future<AppUser> freshIdToken(AppUser user) async {
    if (!user.isTokenExpired) return user;
    return refreshIdToken(user);
  }

  /// Synchronizes user profile to `/users/{userId}` in Cloud Firestore.
  Future<void> _syncUserProfile(AppUser user) async {
    if (!config.isConfigured) return;
    try {
      final dbId = config.firestoreDatabaseId.isEmpty
          ? '(default)'
          : config.firestoreDatabaseId;
      final docUrl = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/$dbId/documents/users/${user.uid}',
      );

      final profileFields = FirestoreRestCodec.encodeFields({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
        'lastActiveAt': DateTime.now().millisecondsSinceEpoch,
      });

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (user.idToken != null && user.idToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${user.idToken}';
      }

      await _client.patch(
        docUrl,
        headers: headers,
        body: jsonEncode({'fields': profileFields}),
      );
    } catch (_) {
      // Non-blocking background profile write
    }
  }

  /// Updates user profile details (such as displayName) and syncs to Firestore & local cache.
  Future<void> updateUserProfile(AppUser user) async {
    await _syncUserProfile(user);
    await _saveCachedUser(user);
  }

  /// Deletes user document from Firestore and deletes account in Firebase Auth (GDPR right-to-erasure).
  Future<void> deleteUserAccount(AppUser user) async {
    _ensureConfigured();

    // 1. Delete user profile doc
    try {
      final dbId = config.firestoreDatabaseId.isEmpty
          ? '(default)'
          : config.firestoreDatabaseId;
      final docUrl = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/$dbId/documents/users/${user.uid}',
      );
      final headers = <String, String>{};
      if (user.idToken != null)
        headers['Authorization'] = 'Bearer ${user.idToken}';
      await _client.delete(docUrl, headers: headers);
    } catch (_) {}

    // 2. Delete Auth account
    if (user.idToken != null && user.idToken!.isNotEmpty) {
      final authUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${config.apiKey}',
      );
      await _client.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': user.idToken}),
      );
    }

    await signOut();
  }

  /// Signs out user and removes cached session.
  Future<void> signOut() async {
    await _saveCachedUser(null);
  }

  void _ensureConfigured() {
    if (!config.isConfigured) {
      throw Exception(
        'Firebase is not configured. Please provide an API Key and Project ID in Cloud Sync Settings.',
      );
    }
  }

  String _parseError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      if (map.containsKey('error')) {
        final err = map['error'];
        if (err is Map && err.containsKey('message')) {
          return err['message'].toString();
        }
      }
    } catch (_) {}
    return body;
  }
}
