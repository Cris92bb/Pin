import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/sync/services/google_sso_service.dart';

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

    test('isSuccess is false when idToken is null or empty', () {
      const result1 = GoogleSsoResult(errorMessage: 'Sign-in failed');
      expect(result1.isSuccess, isFalse);

      const result2 = GoogleSsoResult(idToken: '');
      expect(result2.isSuccess, isFalse);
    });

    test('isCancelled is preserved correctly', () {
      const result = GoogleSsoResult(isCancelled: true);
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
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
      // Calling cancel when idle should be completely safe and not throw
      expect(() => service.cancel(), returnsNormally);
    });
  });
}
