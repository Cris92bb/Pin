import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:http/http.dart' as http;
import '../google_sso_result.dart';
import 'google_sso_runner.dart';

@JS('pinGoogleSsoRequestAuth')
external JSPromise<JSString> _jsPinGoogleSsoRequestAuth(JSString clientId);

/// Instantiates the web Google SSO runner using Google Identity Services.
GoogleSsoPlatformRunner createPlatformRunner({http.Client? httpClient}) =>
    GoogleSsoWebRunner(httpClient: httpClient);

/// Web implementation of Google SSO utilizing Google Identity Services (GIS).
class GoogleSsoWebRunner implements GoogleSsoPlatformRunner {
  final http.Client _httpClient;
  Completer<GoogleSsoResult>? _completer;

  GoogleSsoWebRunner({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<GoogleSsoResult> signIn({
    required String clientId,
    String? clientSecret,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    cancel();

    if (clientId.trim().isEmpty) {
      return const GoogleSsoResult(
        errorMessage: 'Google OAuth Client ID is not configured.',
      );
    }

    final completer = Completer<GoogleSsoResult>();
    _completer = completer;

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(
          const GoogleSsoResult(
            isCancelled: true,
            errorMessage: 'Sign-in timed out. Please try again.',
          ),
        );
      }
    });

    try {
      final jsPromise = _jsPinGoogleSsoRequestAuth(clientId.trim().toJS);
      final rawResultJs = await jsPromise.toDart;
      final rawJson = rawResultJs.toDart;

      timer.cancel();
      if (completer.isCompleted) return await completer.future;

      final data = jsonDecode(rawJson) as Map<String, dynamic>;

      if (data['isCancelled'] == true) {
        const result = GoogleSsoResult(isCancelled: true);
        completer.complete(result);
        return result;
      }

      final errorMsg = data['errorMessage'] as String?;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        final result = GoogleSsoResult(errorMessage: errorMsg);
        completer.complete(result);
        return result;
      }

      final accessToken = data['accessToken'] as String?;
      final idToken = data['idToken'] as String?;

      if ((accessToken == null || accessToken.isEmpty) &&
          (idToken == null || idToken.isEmpty)) {
        const result = GoogleSsoResult(
          errorMessage: 'No authentication token received from Google.',
        );
        completer.complete(result);
        return result;
      }

      String? email = data['email'] as String?;
      String? displayName = data['displayName'] as String?;
      String? photoUrl = data['photoUrl'] as String?;

      // If profile not provided directly by GIS ID token, fetch via UserInfo
      if (accessToken != null && accessToken.isNotEmpty && email == null) {
        try {
          final userInfoResponse = await _httpClient.get(
            Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          if (userInfoResponse.statusCode >= 200 &&
              userInfoResponse.statusCode < 300) {
            final info =
                jsonDecode(userInfoResponse.body) as Map<String, dynamic>;
            email = info['email'] as String?;
            displayName = info['name'] as String?;
            photoUrl = info['picture'] as String?;
          }
        } catch (_) {}
      }

      final result = GoogleSsoResult(
        idToken: idToken,
        accessToken: accessToken,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      completer.complete(result);
      return result;
    } catch (e) {
      timer.cancel();
      final result = GoogleSsoResult(
        errorMessage: 'Google SSO failed on web: ${e.toString()}',
      );
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    }
  }

  @override
  void cancel() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(const GoogleSsoResult(isCancelled: true));
    }
    _completer = null;
  }
}
