import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
/// using a local loopback server and Google Identity Services (GIS).
class GoogleSsoService {
  HttpServer? _server;
  Completer<GoogleSsoResult>? _completer;
  Timer? _timeoutTimer;

  /// Launches Google SSO in the system browser and waits for the user to authenticate.
  Future<GoogleSsoResult> signIn({
    required String clientId,
    Duration timeout = const Duration(minutes: 2),
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
      final ssoUrl = 'http://127.0.0.1:$port/sso';

      // 2. Set timeout timer
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

      // 3. Listen for requests
      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;

        if (path == '/sso') {
          // Serve the Google Identity Services HTML page
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(_buildSsoHtml(clientId: clientId, port: port));
          await request.response.close();
        } else if (path == '/callback' && request.method == 'POST') {
          try {
            final body = await utf8.decoder.bind(request).join();
            final data = jsonDecode(body) as Map<String, dynamic>;
            final idToken = data['idToken'] as String?;

            if (idToken != null && idToken.isNotEmpty) {
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.json
                ..write(jsonEncode({'status': 'ok'}));
              await request.response.close();

              // Extract any payload info from ID token JWT
              final profile = _decodeJwtPayload(idToken);

              if (!completer.isCompleted) {
                completer.complete(
                  GoogleSsoResult(
                    idToken: idToken,
                    email: profile?['email'] as String?,
                    displayName: profile?['name'] as String?,
                    photoUrl: profile?['picture'] as String?,
                  ),
                );
              }
              _cleanUp();
            } else {
              request.response
                ..statusCode = HttpStatus.badRequest
                ..write('Missing idToken');
              await request.response.close();
            }
          } catch (e) {
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write('Error parsing callback');
            await request.response.close();
          }
        } else if (path == '/cancel') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write('<html><body><p>Sign-in cancelled.</p></body></html>');
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(
              const GoogleSsoResult(isCancelled: true),
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

      // 4. Open the system browser
      await _openBrowser(ssoUrl);

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

  String _buildSsoHtml({required String clientId, required int port}) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign in to Pin</title>
  <script src="https://accounts.google.com/gsi/client" async defer></script>
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
      padding: 36px 28px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 52px;
      height: 52px;
      background: #1C2720;
      border: 1.5px solid #334D3D;
      border-radius: 16px;
      font-size: 26px;
      margin-bottom: 18px;
    }
    h1 {
      font-size: 20px;
      font-weight: 800;
      color: #FFFFFF;
      letter-spacing: -0.3px;
      margin-bottom: 8px;
    }
    p {
      font-size: 13px;
      color: #8C9C93;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .btn-container {
      display: flex;
      justify-content: center;
      margin-bottom: 18px;
      min-height: 48px;
    }
    .success-container {
      display: none;
      padding: 16px;
      background: #162C20;
      border: 1px solid #34D399;
      border-radius: 12px;
      color: #34D399;
      font-weight: 600;
      font-size: 14px;
      animation: fadeIn 0.3s ease;
    }
    .status-text {
      font-size: 12px;
      color: #6EE7B7;
      margin-top: 10px;
      display: none;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(6px); }
      to { opacity: 1; transform: translateY(0); }
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">📌</div>
    <h1>Sign in with Google</h1>
    <p>Authenticate with your Google account to sync your Pin Kanban board across your desktop and watch.</p>

    <div id="btn-box" class="btn-container">
      <div id="g_id_onload"
           data-client_id="$clientId"
           data-callback="onGoogleCredential"
           data-auto_prompt="true">
      </div>
      <div class="g_id_signin"
           data-type="standard"
           data-size="large"
           data-theme="filled_black"
           data-text="continue_with"
           data-shape="pill"
           data-logo_alignment="left">
      </div>
    </div>

    <div id="status" class="status-text">Completing authentication with Pin...</div>

    <div id="success" class="success-container">
      ✓ Google Sign-In Successful!<br>
      <span style="font-size: 11px; font-weight: normal; color: #A7F3D0;">You can close this tab and return to Pin.</span>
    </div>
  </div>

  <script>
    function onGoogleCredential(response) {
      if (!response || !response.credential) return;

      document.getElementById('btn-box').style.display = 'none';
      document.getElementById('status').style.display = 'block';

      fetch('http://127.0.0.1:$port/callback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken: response.credential })
      })
      .then(function(res) { return res.json(); })
      .then(function() {
        document.getElementById('status').style.display = 'none';
        document.getElementById('success').style.display = 'block';
        setTimeout(function() {
          try { window.close(); } catch(e) {}
        }, 1500);
      })
      .catch(function() {
        document.getElementById('status').innerText = 'Sync failed. Please return to Pin.';
        document.getElementById('status').style.color = '#F87171';
      });
    }
  </script>
</body>
</html>''';
  }
}
