import 'package:google_sign_in/google_sign_in.dart';
import '../google_sso_result.dart';
import 'google_sso_runner.dart';

/// Mobile implementation of Google SSO via the `google_sign_in` Flutter plugin.
///
/// Uses Google's native sign-in UI on Android (Credential Manager / One Tap)
/// and iOS (GIDSignIn) to present the account chooser and obtain OAuth tokens.
/// The resulting [GoogleSsoResult] carries the `idToken` and `accessToken`
/// needed by [FirebaseAuthService.signInWithGoogleSso].
class GoogleSsoMobileRunner implements GoogleSsoPlatformRunner {
  GoogleSignIn? _googleSignIn;

  @override
  Future<GoogleSsoResult> signIn({
    required String clientId,
    String? clientSecret,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (clientId.trim().isEmpty) {
      return const GoogleSsoResult(
        errorMessage: 'Google OAuth Client ID is not configured.',
      );
    }

    try {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: clientId.trim(),
      );

      final account = await _googleSignIn!.signIn();

      if (account == null) {
        // User dismissed the account picker.
        return const GoogleSsoResult(isCancelled: true);
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      final accessToken = authentication.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        return const GoogleSsoResult(
          errorMessage:
              'Google Sign-In completed but returned no authentication tokens. '
              'Ensure the app SHA-1 fingerprint is registered in the '
              'Google Cloud Console.',
        );
      }

      return GoogleSsoResult(
        idToken: idToken,
        accessToken: accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      final message = e.toString();

      // Handle common known error codes.
      if (message.contains('sign_in_canceled') ||
          message.contains('CANCELED') ||
          message.contains('canceled')) {
        return const GoogleSsoResult(isCancelled: true);
      }
      if (message.contains('network_error') ||
          message.contains('NETWORK_ERROR')) {
        return const GoogleSsoResult(
          errorMessage:
              'Network error during Google Sign-In. Please check your '
              'internet connection and try again.',
        );
      }

      return GoogleSsoResult(
        errorMessage: 'Google Sign-In failed: $message',
      );
    }
  }

  @override
  void cancel() {
    _googleSignIn?.disconnect();
    _googleSignIn = null;
  }
}
