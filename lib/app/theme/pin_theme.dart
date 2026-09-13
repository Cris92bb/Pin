import 'package:flutter/material.dart';
import '../../shared/ui/pin_tokens.dart';

/// App theme configuration for Pin's companion experience.
class PinTheme {
  const PinTheme._();

  /// Crisp high-contrast light theme matching the companion screenshot.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PinTokens.lightCanvasBg,
      canvasColor: PinTokens.lightPhoneFrameBg,
      cardColor: PinTokens.lightCardBg,
      dividerColor: PinTokens.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: PinTokens.lightFabBg,
        secondary: PinTokens.lightActiveFocus,
        surface: PinTokens.lightSheetBg,
        surfaceContainerHighest: PinTokens.lightTagBg,
        error: PinTokens.accentRose,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: PinTokens.lightTextPrimary,
      ),
      fontFamily: 'sans-serif',
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: PinTokens.lightFabBg,
          borderRadius: PinTokens.radiusSm,
        ),
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Calm obsidian dark theme.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PinTokens.darkCanvasBg,
      canvasColor: PinTokens.darkPhoneFrameBg,
      cardColor: PinTokens.darkCardBg,
      dividerColor: PinTokens.darkBorderSubtle,
      colorScheme: const ColorScheme.dark(
        primary: PinTokens.accentEmerald,
        secondary: PinTokens.darkActiveFocus,
        surface: PinTokens.darkCardBg,
        surfaceContainerHighest: PinTokens.darkTagBg,
        error: PinTokens.accentRose,
        onPrimary: PinTokens.darkPhoneFrameBg,
        onSecondary: Colors.white,
        onSurface: PinTokens.darkTextPrimary,
      ),
      fontFamily: 'sans-serif',
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: PinTokens.darkCardBg,
          borderRadius: PinTokens.radiusSm,
          border: Border.all(color: PinTokens.darkBorder),
        ),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: PinTokens.darkTextPrimary,
        ),
      ),
    );
  }
}
