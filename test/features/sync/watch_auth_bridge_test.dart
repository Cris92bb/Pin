import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/sync/model/app_user.dart';
import 'package:pin/features/sync/services/watch_auth_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.pin/watch_auth');

  setUp(() {
    WatchAuthBridge.resetInstance();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PhoneAuthRequestResult', () {
    test('instantiates with success and user', () {
      const user = AppUser(
        uid: 'user-123',
        email: 'watch@example.com',
        displayName: 'Watch User',
        idToken: 'mock-token',
      );
      const result = PhoneAuthRequestResult(success: true, user: user);
      expect(result.success, isTrue);
      expect(result.user?.email, equals('watch@example.com'));
      expect(result.errorMessage, isNull);
    });

    test('instantiates with failure and errorMessage', () {
      const result = PhoneAuthRequestResult(
        success: false,
        errorMessage: 'Connection timed out',
      );
      expect(result.success, isFalse);
      expect(result.user, isNull);
      expect(result.errorMessage, equals('Connection timed out'));
    });
  });

  group('AppUser Serialization for Wearable Data Layer', () {
    test('encodes and decodes full AppUser payload accurately', () {
      const original = AppUser(
        uid: 'user-abc-456',
        email: 'cristun92xd@gmail.com',
        displayName: 'Cristian Dudca',
        photoURL: 'https://example.com/avatar.png',
        idToken: 'jwt-id-token-xyz',
        refreshToken: 'refresh-token-123',
        tokenExpiresAt: 1789430207287,
        isAnonymous: false,
      );

      final jsonStr = jsonEncode(original.toJson());
      final decoded = AppUser.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

      expect(decoded.uid, equals(original.uid));
      expect(decoded.email, equals(original.email));
      expect(decoded.displayName, equals(original.displayName));
      expect(decoded.photoURL, equals(original.photoURL));
      expect(decoded.idToken, equals(original.idToken));
      expect(decoded.refreshToken, equals(original.refreshToken));
      expect(decoded.tokenExpiresAt, equals(original.tokenExpiresAt));
      expect(decoded.isAnonymous, isFalse);
    });
  });
}
