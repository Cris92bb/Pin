import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../model/app_user.dart';

/// Result of requesting companion phone authentication.
class PhoneAuthRequestResult {
  final bool success;
  final AppUser? user;
  final String? errorMessage;

  const PhoneAuthRequestResult({
    required this.success,
    this.user,
    this.errorMessage,
  });
}

/// Service managing cross-device authentication between Wear OS watch and Android companion phone.
class WatchAuthBridge {
  static const MethodChannel _channel = MethodChannel('com.example.pin/watch_auth');
  static WatchAuthBridge? _instance;

  Completer<AppUser?>? _pendingAuthCompleter;

  WatchAuthBridge._() {
    _initChannelListener();
  }

  factory WatchAuthBridge() {
    return _instance ??= WatchAuthBridge._();
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  void _initChannelListener() {
    if (kIsWeb || !Platform.isAndroid) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAuthReceived') {
        final rawJson = call.arguments as String?;
        if (rawJson != null && rawJson.isNotEmpty) {
          try {
            final userMap = jsonDecode(rawJson) as Map<String, dynamic>;
            final user = AppUser.fromJson(userMap);
            if (_pendingAuthCompleter != null && !_pendingAuthCompleter!.isCompleted) {
              _pendingAuthCompleter!.complete(user);
            }
          } catch (e) {
            debugPrint('WatchAuthBridge: Failed to parse user payload: $e');
          }
        }
      }
    });
  }

  /// Sends an authentication request to the paired companion phone via Google Play Services Wearable Data Layer.
  Future<PhoneAuthRequestResult> requestPhoneAuth({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return const PhoneAuthRequestResult(
        success: false,
        errorMessage: 'Companion phone sync is only supported on Android / Wear OS.',
      );
    }

    try {
      final completer = Completer<AppUser?>();
      _pendingAuthCompleter = completer;

      // 1. Check if user is already cached in SharedPreferences
      final localCached = await _channel.invokeMethod<String?>('getCachedUser');
      if (localCached != null && localCached.isNotEmpty) {
        try {
          final user = AppUser.fromJson(jsonDecode(localCached) as Map<String, dynamic>);
          if (user.idToken != null && user.idToken!.isNotEmpty) {
            _pendingAuthCompleter = null;
            return PhoneAuthRequestResult(success: true, user: user);
          }
        } catch (_) {}
      }

      // 2. Dispatch request to paired phone
      final res = await _channel.invokeMapMethod<String, dynamic>('requestPhoneAuth');
      final status = res?['status'] as String?;
      if (status == 'no_nodes') {
        _pendingAuthCompleter = null;
        return const PhoneAuthRequestResult(
          success: false,
          errorMessage: 'No companion phone detected. Please ensure your watch is connected to your phone via Bluetooth.',
        );
      }

      // 3. Await auth response with timeout
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      final user = await completer.future;
      timer.cancel();
      _pendingAuthCompleter = null;

      if (user != null) {
        return PhoneAuthRequestResult(success: true, user: user);
      } else {
        return const PhoneAuthRequestResult(
          success: false,
          errorMessage: 'Sign-in on companion phone timed out. Please open Pin on your phone and try again.',
        );
      }
    } catch (e) {
      _pendingAuthCompleter = null;
      return PhoneAuthRequestResult(
        success: false,
        errorMessage: 'Failed to communicate with companion phone: $e',
      );
    }
  }

  /// Transmits user authentication credentials to any connected watch node.
  Future<void> sendAuthToWatch(AppUser user) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('sendAuthToWatch', {
        'userData': jsonEncode(user.toJson()),
      });
    } catch (e) {
      debugPrint('WatchAuthBridge: Failed to broadcast auth to watch: $e');
    }
  }
}
