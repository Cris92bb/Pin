import 'dart:convert';

/// Result from a Google SSO operation across native desktop and web platforms.
class GoogleSsoResult {
  /// Authentic Google ID token (JWT) obtained from Google OAuth or OIDC.
  final String? idToken;

  /// Authentic OAuth 2.0 access token obtained from Google Identity Services.
  final String? accessToken;

  /// Primary email associated with the authenticated Google account.
  final String? email;

  /// User's display name returned by Google profile.
  final String? displayName;

  /// User's avatar or profile picture URL.
  final String? photoUrl;

  /// Descriptive error message if the sign-in failed.
  final String? errorMessage;

  /// Whether the sign-in operation was dismissed or cancelled by the user.
  final bool isCancelled;

  /// Creates an immutable [GoogleSsoResult] representation.
  const GoogleSsoResult({
    this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.errorMessage,
    this.isCancelled = false,
  });

  /// Whether the SSO operation successfully yielded an authentication token.
  bool get isSuccess =>
      (idToken != null && idToken!.isNotEmpty) ||
      (accessToken != null && accessToken!.isNotEmpty);
}

/// Helper utility for safely extracting claims and profiles from Google JWT tokens.
abstract final class GoogleSsoJwtDecoder {
  /// Decodes and parses the payload segment of a standard three-part JWT token.
  static Map<String, dynamic>? decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
      return payload;
    } catch (_) {
      return null;
    }
  }
}
