import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to synchronize app theme with native platform components
/// (e.g. Linux desktop GTK headerbar, Android/iOS system status bar).
class PlatformThemeService {
  const PlatformThemeService._();

  static const MethodChannel _channel = MethodChannel('pin/theme');

  /// Synchronizes the platform title bar and system UI overlay with the current theme.
  static Future<void> syncTheme({required bool isDark}) async {
    // 1. Synchronize desktop native window (Linux GTK header bar)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      try {
        await _channel.invokeMethod('setTheme', {'isDark': isDark});
      } catch (_) {
        // Channel may not be implemented on test environments
      }
    }

    // 2. Synchronize mobile / web system UI overlay
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          isDark ? const Color(0xFF0B0F17) : const Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }
}
