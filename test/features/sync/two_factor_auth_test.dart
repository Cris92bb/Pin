import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pin/features/sync/services/firebase_auth_service.dart';
import 'package:pin/features/sync/services/firebase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testConfig = FirebaseConfig(
    apiKey: 'mock-key',
    projectId: 'mock-project',
    oAuthClientId: 'mock-client-id.apps.googleusercontent.com',
  );

  group('Two-Factor Authentication (2FA) in FirebaseAuthService', () {
    test('signInWithEmail validates 6-digit format when 2FA code is provided', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'localId': 'user-123',
            'email': 'user@example.com',
            'idToken': 'jwt.token.here',
            'refreshToken': 'refresh-token',
            'expiresIn': '3600',
          }),
          200,
        );
      });

      final authService = FirebaseAuthService(
        client: mockClient,
        config: testConfig,
      );

      // Invalid 2FA code (letters) throws
      expect(
        () => authService.signInWithEmail(
          'user@example.com',
          'password123',
          twoFactorCode: 'abc12',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid 2FA code'),
        )),
      );

      // Valid 6-digit 2FA code succeeds
      final user = await authService.signInWithEmail(
        'user@example.com',
        'password123',
        twoFactorCode: '123456',
      );
      expect(user.uid, equals('user-123'));
      expect(user.email, equals('user@example.com'));
    });

    test('signUpWithEmail validates 6-digit format when 2FA code is provided', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'localId': 'new-user-456',
            'email': 'new@example.com',
            'idToken': 'jwt.token.new',
            'refreshToken': 'refresh-token',
            'expiresIn': '3600',
          }),
          200,
        );
      });

      final authService = FirebaseAuthService(
        client: mockClient,
        config: testConfig,
      );

      // Invalid 2FA code (less than 6 digits) throws
      expect(
        () => authService.signUpWithEmail(
          'new@example.com',
          'password123',
          twoFactorCode: '123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid 2FA code'),
        )),
      );

      // Valid 6-digit 2FA code succeeds
      final user = await authService.signUpWithEmail(
        'new@example.com',
        'password123',
        twoFactorCode: '654321',
      );
      expect(user.uid, equals('new-user-456'));
    });
  });
}
