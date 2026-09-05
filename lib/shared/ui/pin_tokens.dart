import 'package:flutter/material.dart';

/// Design tokens for Pin companion application.
///
/// Designed to support both high-contrast tactile Light Mode (matching screenshot)
/// and calm Obsidian Dark Mode.
class PinTokens {
  const PinTokens._();

  // Light Mode Palette (from screenshot)
  static const Color lightCanvasBg = Color(0xFF18181B); // Outer desktop canvas backdrop
  static const Color lightPhoneFrameBg = Color(0xFFFFFFFF); // Companion card container
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFF111827);
  static const Color lightBorderSubtle = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  static const Color lightActiveFocus = Color(0xFF2563EB); // Royal blue
  static const Color lightMaxFocusBg = Color(0xFFEEF2FF); // Soft indigo tint
  static const Color lightMaxFocusText = Color(0xFF4338CA);
  static const Color lightTagBg = Color(0xFFF3F4F6);
  static const Color lightTagText = Color(0xFF374151);
  static const Color primary = lightActiveFocus;

  // Dark Mode Palette
  static const Color darkCanvasBg = Color(0xFF090A0F);
  static const Color darkPhoneFrameBg = Color(0xFF11141D);
  static const Color darkCardBg = Color(0xFF181C28);
  static const Color darkBorder = Color(0xFF2E3547);
  static const Color darkBorderSubtle = Color(0xFF232838);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkActiveFocus = Color(0xFF60A5FA);
  static const Color darkMaxFocusBg = Color(0xFF1E1B4B);
  static const Color darkMaxFocusText = Color(0xFF818CF8);
  static const Color darkTagBg = Color(0xFF1F2432);
  static const Color darkTagText = Color(0xFFCBD5E1);

  // Backward Compatible Aliases
  static const Color canvasBg = Color(0xFF0D0F14);
  static const Color surfaceHeader = Color(0xFF13161F);
  static const Color surfaceColumn = Color(0xFF171A24);
  static const Color surfaceCard = Color(0xFF1D212E);
  static const Color surfaceCardHover = Color(0xFF24293A);
  static const Color surfaceModal = Color(0xFF161922);
  static const Color surfaceActive = Color(0xFF232838);

  static const Color borderSubtle = Color(0xFF1F2432);
  static const Color borderDefault = Color(0xFF2A3042);
  static const Color borderFocus = Color(0xFF8B5CF6);
  static const Color borderWipAlert = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFF0F172A);

  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  static const Map<String, Color> energyTagColors = {
    'low-friction': Color(0xFF10B981),
    'medium-flow': Color(0xFF0284C7),
    'deep-focus': Color(0xFF8B5CF6),
    'creative': Color(0xFFF59E0B),
    'administrative': Color(0xFF38BDF8),
  };

  // Energy Badges
  static const Color energyLowBg = Color(0xFFDCFCE7);
  static const Color energyLowText = Color(0xFF15803D);
  static const Color energyMediumBg = Color(0xFFF4F1E8);
  static const Color energyMediumText = Color(0xFF1F2937);
  static const Color energyDeepBg = Color(0xFFEEF2FF);
  static const Color energyDeepText = Color(0xFF4338CA);
  static const Color energyCreativeBg = Color(0xFFFEF3C7);
  static const Color energyCreativeText = Color(0xFFB45309);
  static const Color energyAdminBg = Color(0xFFF3F4F6);
  static const Color energyAdminText = Color(0xFF374151);

  // Border Radii
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(6));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusDeck = BorderRadius.all(Radius.circular(28));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999));

  // Spacing scales
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Animations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  // WIP Limit Config
  static const int defaultWipLimit = 5;
  static const int minWipLimit = 4;
  static const int maxWipLimit = 5;
}
