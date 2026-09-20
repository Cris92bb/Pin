import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/sync/services/firebase_config.dart';
import 'package:pin/features/sync/services/google_sso_service.dart';
import 'package:pin/features/sync/services/platform/google_sso_runner.dart';

class _MockRunner implements GoogleSsoPlatformRunner {
  bool cancelled = false;
  GoogleSsoResult nextResult = const GoogleSsoResult(accessToken: 'mock-access');

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

    test('isSuccess is false when idToken and accessToken are null or empty', () {
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
      expect(GoogleSsoJwtDecoder.decodePayload('header.invalid-base-64'), isNull);
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

  group('FirebaseConfig OAuth Secret', () {
    test('serializes and deserializes oAuthClientSecret correctly', () {
      const config = FirebaseConfig(
        apiKey: 'test-api-key',
        projectId: 'test-project',
        oAuthClientId: 'test-client-id.apps.googleusercontent.com',
        oAuthClientSecret: 'GOCSPX-secret123',
      );
      final json = config.toJson();
      expect(json['oAuthClientSecret'], equals('GOCSPX-secret123'));

      final fromJson = FirebaseConfig.fromJson(json);
      expect(fromJson.oAuthClientSecret, equals('GOCSPX-secret123'));
      expect(
        fromJson.oAuthClientId,
        equals('test-client-id.apps.googleusercontent.com'),
      );
    });
  });
}
