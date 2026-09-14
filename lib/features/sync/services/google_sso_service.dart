import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Result from a Google SSO operation.
class GoogleSsoResult {
  final String? idToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? errorMessage;
  final bool isCancelled;

  const GoogleSsoResult({
    this.idToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.errorMessage,
    this.isCancelled = false,
  });

  bool get isSuccess => idToken != null && idToken!.isNotEmpty;
}

/// Service handling Google Single Sign-On (SSO) on native desktop and web
/// using direct Google OAuth 2.0 authorization code flow with loopback listener (RFC 8252).
class GoogleSsoService {
  final http.Client _httpClient;
  HttpServer? _server;
  Completer<GoogleSsoResult>? _completer;
  Timer? _timeoutTimer;

  GoogleSsoService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Launches Google SSO directly into Google's official consent screen in the
  /// system browser and listens on a local loopback port for the authorization response.
  Future<GoogleSsoResult> signIn({
    required String clientId,
    String? clientSecret,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    cancel();

    if (kIsWeb) {
      return const GoogleSsoResult(
        errorMessage: 'Google SSO on web is managed via browser window.',
      );
    }

    if (clientId.trim().isEmpty) {
      return const GoogleSsoResult(
        errorMessage: 'Google OAuth Client ID is not configured.',
      );
    }

    final completer = Completer<GoogleSsoResult>();
    _completer = completer;

    try {
      // 1. Start a local loopback HTTP server on an available port
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = _server!.port;
      final redirectUri = 'http://127.0.0.1:$port/callback';

      // 2. Build direct Google OAuth 2.0 authorization URL
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.trim(),
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'prompt': 'select_account',
        'access_type': 'offline',
      });

      // 3. Set timeout timer
      _timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _cleanUp();
          completer.complete(
            const GoogleSsoResult(
              isCancelled: true,
              errorMessage: 'Sign-in timed out. Please try again.',
            ),
          );
        }
      });

      // 4. Listen for incoming redirect from Google
      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;

        if (path == '/callback') {
          final query = request.uri.queryParameters;
          final error = query['error'];
          final code = query['code'];

          if (error != null) {
            final isAccessDenied = error == 'access_denied';
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(_buildCancelledHtml());
            await request.response.close();

            if (!completer.isCompleted) {
              completer.complete(
                GoogleSsoResult(
                  isCancelled: isAccessDenied,
                  errorMessage: isAccessDenied
                      ? null
                      : 'Google authentication error: $error',
                ),
              );
            }
            _cleanUp();
            return;
          }

          if (code == null || code.isEmpty) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..headers.contentType = ContentType.html
              ..write(_buildErrorHtml('Missing authorization code from Google.'));
            await request.response.close();

            if (!completer.isCompleted) {
              completer.complete(
                const GoogleSsoResult(
                  errorMessage: 'Authorization code missing in Google callback.',
                ),
              );
            }
            _cleanUp();
            return;
          }

          // 1. Release browser immediately with success page so user transitions back to Pin
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(_buildSuccessHtml());
          await request.response.close();

          // 2. Exchange authorization code with retries (accommodating mobile background app network restrictions)
          GoogleSsoResult? ssoResult;
          for (int attempt = 0; attempt < 8; attempt++) {
            try {
              final tokenResponse = await _httpClient.post(
                Uri.parse('https://oauth2.googleapis.com/token'),
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: {
                  'code': code,
                  'client_id': clientId.trim(),
                  if (clientSecret != null && clientSecret.trim().isNotEmpty)
                    'client_secret': clientSecret.trim(),
                  'redirect_uri': redirectUri,
                  'grant_type': 'authorization_code',
                },
              );

              if (tokenResponse.statusCode >= 200 &&
                  tokenResponse.statusCode < 300) {
                final tokenData =
                    jsonDecode(tokenResponse.body) as Map<String, dynamic>;
                final idToken = tokenData['id_token'] as String?;

                if (idToken != null && idToken.isNotEmpty) {
                  final profile = _decodeJwtPayload(idToken);
                  ssoResult = GoogleSsoResult(
                    idToken: idToken,
                    email: profile?['email'] as String?,
                    displayName: profile?['name'] as String?,
                    photoUrl: profile?['picture'] as String?,
                  );
                  break;
                } else {
                  ssoResult = const GoogleSsoResult(
                    errorMessage: 'Missing id_token in Google token response.',
                  );
                  break;
                }
              } else {
                String errorDesc = 'Failed to exchange authorization token.';
                try {
                  final errJson =
                      jsonDecode(tokenResponse.body) as Map<String, dynamic>;
                  errorDesc = errJson['error_description'] as String? ??
                      errJson['error'] as String? ??
                      errorDesc;
                } catch (_) {}
                ssoResult = GoogleSsoResult(
                  errorMessage: 'Google token exchange failed: $errorDesc',
                );
                break;
              }
            } catch (e) {
              if (attempt < 7) {
                await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
                continue;
              }
              ssoResult = GoogleSsoResult(
                errorMessage:
                    'Network error connecting to Google ($e). Please return to Pin and try again.',
              );
            }
          }

          if (!completer.isCompleted) {
            completer.complete(
              ssoResult ??
                  const GoogleSsoResult(
                    errorMessage: 'Authentication timed out. Please try again.',
                  ),
            );
          }
          _cleanUp();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found');
          await request.response.close();
        }
      });

      // 5. Open the system browser directly to Google's OAuth consent screen
      await _openBrowser(authUri.toString());

      return await completer.future;
    } catch (e) {
      _cleanUp();
      return GoogleSsoResult(
        errorMessage: 'Failed to launch Google SSO: ${e.toString()}',
      );
    }
  }

  /// Cancels any active SSO waiting session and closes the server.
  void cancel() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(const GoogleSsoResult(isCancelled: true));
    }
    _cleanUp();
  }

  void _cleanUp() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _server?.close(force: true);
    _server = null;
  }

  Future<void> _openBrowser(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      }
    } catch (_) {}
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
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

  String _buildSuccessHtml({String? email, String? name}) {
    final welcome = name != null && name.isNotEmpty
        ? 'Welcome, $name!'
        : 'Sign-in successful!';
    final accountText = email != null && email.isNotEmpty
        ? 'Connected as <strong>$email</strong>'
        : 'Your Google Account is now connected.';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pin — Authentication Complete</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0E1411;
      color: #E2E8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141A16;
      border: 1px solid #233028;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 420px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 56px;
      height: 56px;
      background: #162C20;
      border: 1.5px solid #34D399;
      border-radius: 18px;
      font-size: 26px;
      color: #34D399;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      color: #FFFFFF;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
      color: #8C9C93;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    strong {
      color: #A7F3D0;
    }
    .hint {
      font-size: 12px;
      color: #556B5D;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✓</div>
    <h1>$welcome</h1>
    <p>$accountText<br>Return to Pin to finish connecting your board.</p>
    <a href="intent://#Intent;package=com.example.pin;scheme=pin;end" style="display:inline-block;padding:12px 24px;background:#34D399;color:#0E1411;font-weight:700;border-radius:12px;text-decoration:none;margin-bottom:16px;font-size:14px;">Open Pin</a>
    <div class="hint">This tab may be closed safely.</div>
  </div>
  <script>
    setTimeout(function() {
      try { window.location.href = "intent://#Intent;package=com.example.pin;scheme=pin;end"; } catch(e) {}
      try { window.close(); } catch(e) {}
    }, 500);
  </script>
</body>
</html>''';
  }

  String _buildCancelledHtml() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pin — Sign-In Cancelled</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0E1411;
      color: #E2E8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141A16;
      border: 1px solid #233028;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 420px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 56px;
      height: 56px;
      background: #2A1F1D;
      border: 1.5px solid #F87171;
      border-radius: 18px;
      font-size: 26px;
      color: #F87171;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      color: #FFFFFF;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
      color: #8C9C93;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .hint {
      font-size: 12px;
      color: #556B5D;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✕</div>
    <h1>Sign-In Cancelled</h1>
    <p>You cancelled Google authentication.<br>You can return to Pin to try again.</p>
    <div class="hint">This tab may be closed safely.</div>
  </div>
</body>
</html>''';
  }

  String _buildErrorHtml(String errorMessage) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pin — Authentication Error</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0E1411;
      color: #E2E8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141A16;
      border: 1px solid #3E2424;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 56px;
      height: 56px;
      background: #2A1717;
      border: 1.5px solid #EF4444;
      border-radius: 18px;
      font-size: 26px;
      color: #EF4444;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      color: #FFFFFF;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
      color: #F87171;
      line-height: 1.6;
      margin-bottom: 24px;
      word-break: break-word;
    }
    .hint {
      font-size: 12px;
      color: #556B5D;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">!</div>
    <h1>Authentication Error</h1>
    <p>$errorMessage</p>
    <div class="hint">You can close this tab and return to Pin.</div>
  </div>
</body>
</html>''';
  }
}
