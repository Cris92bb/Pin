import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../google_sso_desktop_html.dart';
import '../google_sso_result.dart';
import 'google_sso_runner.dart';

/// Instantiates the native desktop loopback SSO runner.
GoogleSsoPlatformRunner createPlatformRunner({http.Client? httpClient}) =>
    GoogleSsoDesktopRunner(httpClient: httpClient);

/// Native desktop implementation of Google SSO via RFC 8252 loopback redirect.
class GoogleSsoDesktopRunner implements GoogleSsoPlatformRunner {
  final http.Client _httpClient;
  final Future<void> Function(String url)? _browserLauncher;
  HttpServer? _server;
  Completer<GoogleSsoResult>? _completer;
  Timer? _timeoutTimer;

  /// Visible for unit testing to inspect loopback listener state.
  @visibleForTesting
  HttpServer? get activeServer => _server;

  GoogleSsoDesktopRunner({
    http.Client? httpClient,
    Future<void> Function(String url)? browserLauncher,
  })  : _httpClient = httpClient ?? http.Client(),
        _browserLauncher = browserLauncher;

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

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final port = _server!.port;
      final redirectUri = 'http://127.0.0.1:$port/callback';

      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.trim(),
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'prompt': 'select_account',
        'access_type': 'offline',
      });

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

      _server!.listen((HttpRequest request) async {
        // Enforce CORS and Chromium Private Network Access (PNA) headers for loopback access
        request.response.headers
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
          ..set('Access-Control-Allow-Headers', '*')
          ..set('Access-Control-Allow-Private-Network', 'true');

        // Handle Chromium Local/Private Network Access OPTIONS preflight without closing session
        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          return;
        }

        if (request.uri.path != '/callback') {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found');
          await request.response.close();
          return;
        }

        final query = request.uri.queryParameters;
        final error = query['error'];
        final code = query['code'];

        if (error != null) {
          final isAccessDenied = error == 'access_denied';
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(GoogleSsoDesktopHtml.buildCancelledHtml());
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(GoogleSsoResult(
              isCancelled: isAccessDenied,
              errorMessage:
                  isAccessDenied ? null : 'Google authentication error: $error',
            ));
          }
          _cleanUp();
          return;
        }

        if (code == null || code.isEmpty) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.html
            ..write(GoogleSsoDesktopHtml.buildErrorHtml(
              'Missing authorization code from Google.',
            ));
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(const GoogleSsoResult(
              errorMessage: 'Authorization code missing in Google callback.',
            ));
          }
          _cleanUp();
          return;
        }

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(GoogleSsoDesktopHtml.buildSuccessHtml());
        await request.response.close();

        final ssoResult = await _exchangeCodeWithRetry(
          code: code,
          clientId: clientId,
          clientSecret: clientSecret,
          redirectUri: redirectUri,
        );

        if (Platform.isAndroid || Platform.isIOS) {
          try {
            await closeInAppWebView();
          } catch (_) {}
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
      });

      await _openBrowser(authUri.toString());
      return await completer.future;
    } catch (e) {
      _cleanUp();
      return GoogleSsoResult(
        errorMessage: 'Failed to launch Google SSO: ${e.toString()}',
      );
    }
  }

  @override
  void cancel() {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        closeInAppWebView();
      } catch (_) {}
    }
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

  Future<GoogleSsoResult?> _exchangeCodeWithRetry({
    required String code,
    required String clientId,
    String? clientSecret,
    required String redirectUri,
  }) async {
    const maxAttempts = 30;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
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

        if (tokenResponse.statusCode >= 200 && tokenResponse.statusCode < 300) {
          final tokenData =
              jsonDecode(tokenResponse.body) as Map<String, dynamic>;
          final idToken = tokenData['id_token'] as String?;
          final accessToken = tokenData['access_token'] as String?;

          if (idToken != null && idToken.isNotEmpty) {
            final profile = GoogleSsoJwtDecoder.decodePayload(idToken);
            return GoogleSsoResult(
              idToken: idToken,
              accessToken: accessToken,
              email: profile?['email'] as String?,
              displayName: profile?['name'] as String?,
              photoUrl: profile?['picture'] as String?,
            );
          }
          return const GoogleSsoResult(
            errorMessage: 'Missing id_token in Google token response.',
          );
        }

        String errorDesc = 'Failed to exchange authorization token.';
        try {
          final errJson =
              jsonDecode(tokenResponse.body) as Map<String, dynamic>;
          errorDesc = errJson['error_description'] as String? ??
              errJson['error'] as String? ??
              errorDesc;
        } catch (_) {}
        return GoogleSsoResult(
          errorMessage: 'Google token exchange failed: $errorDesc',
        );
      } catch (e) {
        if (attempt < maxAttempts - 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
          continue;
        }
        return GoogleSsoResult(
          errorMessage:
              'Network error connecting to Google ($e). Please try again.',
        );
      }
    }
    return null;
  }

  Future<void> _openBrowser(String url) async {
    if (_browserLauncher != null) {
      await _browserLauncher(url);
      return;
    }
    final uri = Uri.parse(url);
    final isMobile = Platform.isAndroid || Platform.isIOS;
    try {
      if (isMobile &&
          await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        return;
      }
      if (await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    try {
      final cmd =
          Platform.isLinux ? 'xdg-open' : (Platform.isMacOS ? 'open' : null);
      if (cmd != null) {
        await Process.run(cmd, [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      }
    } catch (_) {}
  }
}
