import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/sync/services/firebase_config.dart';
import 'package:pin/features/sync/services/google_sso_desktop_html.dart';
import 'package:pin/features/sync/services/google_sso_service.dart';
import 'package:pin/features/sync/services/platform/google_sso_runner.dart';
import 'package:pin/features/sync/services/platform/google_sso_runner_io.dart';

class _MockRunner implements GoogleSsoPlatformRunner {
  bool cancelled = false;
  GoogleSsoResult nextResult =
      const GoogleSsoResult(accessToken: 'mock-access');

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
    return nextResult;
  }

  @override
  void cancel() {
    cancelled = true;
  }
}

void main() {
  group('GoogleSsoResult', () {
    test('isSuccess is true when idToken is present and non-empty', () {
      const result = GoogleSsoResult(
        idToken: 'mock-google-id-token',
        email: 'test@gmail.com',
        displayName: 'Test User',
      );
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.idToken, equals('mock-google-id-token'));
      expect(result.email, equals('test@gmail.com'));
      expect(result.displayName, equals('Test User'));
    });

    test('isSuccess is true when accessToken is present and non-empty', () {
      const result = GoogleSsoResult(
        accessToken: 'mock-google-access-token',
        email: 'web@gmail.com',
        displayName: 'Web User',
      );
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.accessToken, equals('mock-google-access-token'));
      expect(result.email, equals('web@gmail.com'));
    });

    test('isSuccess is true when both idToken and accessToken are present', () {
      const result = GoogleSsoResult(
        idToken: 'mock-id-token',
        accessToken: 'mock-access-token',
      );
      expect(result.isSuccess, isTrue);
    });

    test('isSuccess is false when idToken and accessToken are null or empty',
        () {
      const result1 = GoogleSsoResult(errorMessage: 'Sign-in failed');
      expect(result1.isSuccess, isFalse);

      const result2 = GoogleSsoResult(idToken: '', accessToken: '');
      expect(result2.isSuccess, isFalse);
    });

    test('isCancelled is preserved correctly', () {
      const result = GoogleSsoResult(isCancelled: true);
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
    });
  });

  group('GoogleSsoJwtDecoder', () {
    test('decodes valid three-part JWT payload', () {
      final header = base64Url.encode(utf8.encode('{"alg":"RS256"}'));
      final payload = base64Url.encode(utf8.encode(
        '{"email":"john@example.com","name":"John Doe","sub":"12345"}',
      ));
      final jwt = '$header.$payload.signature';

      final claims = GoogleSsoJwtDecoder.decodePayload(jwt);
      expect(claims, isNotNull);
      expect(claims!['email'], equals('john@example.com'));
      expect(claims['name'], equals('John Doe'));
      expect(claims['sub'], equals('12345'));
    });

    test('handles malformed or invalid tokens gracefully', () {
      expect(GoogleSsoJwtDecoder.decodePayload(''), isNull);
      expect(GoogleSsoJwtDecoder.decodePayload('not-a-jwt'), isNull);
      expect(
          GoogleSsoJwtDecoder.decodePayload('header.invalid-base-64'), isNull);
    });
  });

  group('GoogleSsoService', () {
    test('returns error when clientId is empty', () async {
      final service = GoogleSsoService();
      final result = await service.signIn(clientId: '');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Client ID is not configured'));
    });

    test('cancel() cancels any pending SSO flow', () {
      final service = GoogleSsoService();
      expect(() => service.cancel(), returnsNormally);
    });

    test('delegates signIn and cancel to injected runner', () async {
      final mockRunner = _MockRunner();
      final service = GoogleSsoService(runner: mockRunner);

      final result = await service.signIn(clientId: 'test-client-id');
      expect(result.isSuccess, isTrue);
      expect(result.accessToken, equals('mock-access'));

      service.cancel();
      expect(mockRunner.cancelled, isTrue);
    });
  });

  group('FirebaseConfig OAuth Secret and Web Client ID', () {
    test(
        'serializes and deserializes oAuthClientSecret and webOAuthClientId correctly',
        () {
      const config = FirebaseConfig(
        apiKey: 'test-api-key',
        projectId: 'test-project',
        oAuthClientId: 'desktop-client-id.apps.googleusercontent.com',
        oAuthClientSecret: 'GOCSPX-secret123',
        webOAuthClientId: 'web-client-id.apps.googleusercontent.com',
      );
      final json = config.toJson();
      expect(json['oAuthClientSecret'], equals('GOCSPX-secret123'));
      expect(json['webOAuthClientId'],
          equals('web-client-id.apps.googleusercontent.com'));

      final fromJson = FirebaseConfig.fromJson(json);
      expect(fromJson.oAuthClientSecret, equals('GOCSPX-secret123'));
      expect(
        fromJson.oAuthClientId,
        equals('desktop-client-id.apps.googleusercontent.com'),
      );
      expect(
        fromJson.webOAuthClientId,
        equals('web-client-id.apps.googleusercontent.com'),
      );
    });

    test('activeOAuthClientId resolves correctly', () {
      const desktopOnly = FirebaseConfig(
        oAuthClientId: 'desktop-id',
      );
      expect(desktopOnly.activeOAuthClientId, equals('desktop-id'));
    });
  });

  group('GoogleSsoDesktopHtml', () {
    test(
        'buildSuccessHtml renders deep link pin://auth and intent URI fallback',
        () {
      final html = GoogleSsoDesktopHtml.buildSuccessHtml(
        email: 'alice@example.com',
        name: 'Alice',
      );
      expect(html, contains('Welcome, Alice!'));
      expect(html, contains('pin://auth'));
      expect(
          html,
          contains(
              'intent://auth#Intent;scheme=pin;package=com.example.pin;end'));
      expect(html, contains('tryLaunchPin'));
      expect(html, contains('open-pin-btn'));
    });

    test('buildCancelledHtml renders Return to Pin deep link', () {
      final html = GoogleSsoDesktopHtml.buildCancelledHtml();
      expect(html, contains('Sign-In Cancelled'));
      expect(html, contains('pin://auth'));
      expect(html, contains('Return to Pin'));
    });

    test('buildErrorHtml renders error message and Return to Pin deep link',
        () {
      final html = GoogleSsoDesktopHtml.buildErrorHtml('Network unreachable');
      expect(html, contains('Authentication Error'));
      expect(html, contains('Network unreachable'));
      expect(html, contains('pin://auth'));
      expect(html, contains('Return to Pin'));
    });
  });

  group('GoogleSsoDesktopRunner Loopback Server', () {
    test(
        'handles OPTIONS preflight with Private Network Access headers and processes callback',
        () async {
      final prevOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = prevOverrides);

      final runner = GoogleSsoDesktopRunner(browserLauncher: (_) async {});
      final signInFuture = runner.signIn(clientId: 'test-client-id');

      // Wait briefly for the server to bind
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final server = runner.activeServer;
      expect(server, isNotNull);
      final port = server!.port;

      final client = HttpClient();

      // 1. Send an OPTIONS preflight request (Chromium Private Network Access)
      final optionsReq = await client.openUrl(
          'OPTIONS', Uri.parse('http://127.0.0.1:$port/callback'));
      optionsReq.headers.set('Access-Control-Request-Private-Network', 'true');
      final optionsResp = await optionsReq.close();

      expect(optionsResp.statusCode, equals(HttpStatus.noContent));
      expect(optionsResp.headers.value('Access-Control-Allow-Private-Network'),
          equals('true'));
      expect(optionsResp.headers.value('Access-Control-Allow-Origin'),
          equals('*'));

      // 2. Send GET request with access_denied error (simulating user cancel)
      final getReq = await client.getUrl(
          Uri.parse('http://127.0.0.1:$port/callback?error=access_denied'));
      final getResp = await getReq.close();
      expect(getResp.statusCode, equals(HttpStatus.ok));
      expect(getResp.headers.value('Access-Control-Allow-Private-Network'),
          equals('true'));
      expect(getResp.headers.value('Access-Control-Allow-Origin'), equals('*'));
      await getResp.drain<void>();

      // 3. Verify runner completed cleanly
      final result = await signInFuture;
      expect(result.isCancelled, isTrue);
      expect(runner.activeServer, isNull);
      client.close();
    });
  });
}
