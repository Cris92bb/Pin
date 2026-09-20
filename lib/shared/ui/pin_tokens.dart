import 'package:flutter/material.dart';

/// Design tokens for Pin companion application.
///
/// Designed to support both high-contrast tactile Light Mode (matching screenshot)
/// and calm Obsidian Dark Mode.
class PinTokens {
  const PinTokens._();

  // Light Mode Palette (Faded Sage Green Design Palette)
  static const Color lightCanvasBg =
      Color(0xFFF3F5EE); // Main page backdrop behind the card stack
  static const Color lightPhoneFrameBg =
      Color(0xFFF3F5EE); // Companion container background
  static const Color lightSheetBg =
      Color(0xFFE7ECE1); // Active bottom sheet / sliding sheet body surface
  static const Color lightStackedTabBg =
      Color(0xFFDEE3D7); // Stacked card tabs (Backlog & Done)
  static const Color lightCardBg =
      Color(0xFFEFF3EA); // Foreground inner task item cards
  static const Color lightBorder =
      Color(0xFFD4DCCE); // Subtle leafy gray card borders & dividers
  static const Color lightBorderSubtle = Color(0xFFD4DCCE);
  static const Color lightTextPrimary =
      Color(0xFF1A241E); // Deep forest near-black
  static const Color lightTextSecondary = Color(0xFF5F6D64); // Muted sage slate
  static const Color lightTextTertiary = Color(
      0xFF8E9C92); // Soft olive-slate for unpin, trash, radio ring, grab handle
  static const Color lightTextMuted = Color(0xFF8E9C92);
  static const Color lightFabBg =
      Color(0xFF2B3B32); // Dark spruce evergreen action accent
  static const Color lightActiveFocus = Color(
      0xFF2B3B32); // Dark spruce evergreen for active focus & completed progress
  static const Color lightMaxFocusBg =
      Color(0xFFDEE3D7); // Muted desaturated olive-gray
  static const Color lightMaxFocusText = Color(0xFF1A241E);
  static const Color lightTagBg =
      Color(0xFFE2E9DC); // Ultra-light desaturated fill
  static const Color lightTagText = Color(0xFF5F6D64);
  static const Color primary = lightFabBg;

  // Header Utility Accent Tokens (Light Mode)
  static const Color headerSyncBgLight =
      Color(0xFFDEE3D7); // Muted desaturated olive-gray base
  static const Color headerSyncBorderLight =
      Color(0xFFD4DCCE); // Leafy gray border
  static const Color headerSyncFgLight = Color(0xFF1A241E); // Deep forest icon
  static const Color headerThemeBgLight = Color(0xFFDEE3D7);
  static const Color headerThemeBorderLight = Color(0xFFD4DCCE);
  static const Color headerThemeFgLight = Color(0xFF1A241E);
  static const Color headerSyncBorderMedium = Color(0xFFA7D7BE);
  static const Color noticeErrorBgLight = dangerBgLight;

  // Dark Mode Palette
  static const Color darkCanvasBg =
      Color(0xFF0D1117); // App Canvas / Root: Deep obsidian slate
  static const Color darkPhoneFrameBg =
      Color(0xFF0D1117); // Base viewport background
  static const Color darkStackedTabBg =
      Color(0xFF161B22); // Collapsed Cards Layer: Dark charcoal slate
  static const Color darkSheetBg =
      Color(0xFF11161D); // Active Sheet Background: Deep gunmetal blue-gray
  static const Color darkCardBg =
      Color(0xFF18202A); // Task Card Surface: Muted twilight blue-black
  static const Color darkBorder =
      Color(0xFF26303D); // Border / Hairline: Low-contrast steel slate
  static const Color darkBorderSubtle = Color(0xFF26303D);
  static const Color darkTextPrimary =
      Color(0xFFE6EDF3); // Text Primary: Crisp frosted white
  static const Color darkTextSecondary =
      Color(0xFF8B949E); // Text Secondary: Cool stone gray
  static const Color darkTextTertiary =
      Color(0xFF64748B); // Tertiary Icons: Desaturated slate
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkFabBg =
      Color(0xFF1F2937); // FAB (Floating Button): Elevated dark charcoal
  static const Color darkActiveFocus = Color(0xFFA5B4FC);
  static const Color darkMaxFocusBg = Color(0xFF22243C);
  static const Color darkMaxFocusText = Color(0xFFA5B4FC);
  static const Color darkTagBg = Color(0xFF11161D);
  static const Color darkTagText = Color(0xFF8B949E);

  // Tag & Semantic Accents (Dark Mode Adjusted)
  static const Color darkEnergyLowBg = Color(0xFF162E25);
  static const Color darkEnergyLowText = Color(0xFF4ADE80);
  static const Color darkEnergyMediumBg = Color(0xFF2F2119);
  static const Color darkEnergyMediumText = Color(0xFFFB923C);
  static const Color darkEnergyFocusBg = Color(0xFF22243C);
  static const Color darkEnergyFocusText = Color(0xFFA5B4FC);
  static const Color darkEnergyCreativeBg = Color(0xFF2D2311);
  static const Color darkEnergyCreativeText = Color(0xFFFCD34D);
  static const Color darkEnergyAdminBg = Color(0xFF1F2432);
  static const Color darkEnergyAdminText = Color(0xFF94A3B8);
  static const Color darkTimerBg = Color(0xFF22243C);
  static const Color darkTimerText = Color(0xFFA5B4FC);

  // Brand & Identity Tokens
  static const Color googleBlue = Color(0xFF4285F4);

  // Danger & Destructive Action Tokens
  static const Color dangerBgLight = Color(0xFFFDF2F2);
  static const Color dangerHoverLight = Color(0xFFFDE8E8);
  static const Color dangerFgLight = Color(0xFFB91C1C);
  static const Color dangerBorderLight = Color(0xFFFCA5A5);
  static const Color dangerBgDark = Color(0xFF2C1518);
  static const Color dangerHoverDark = Color(0xFF381A1E);
  static const Color dangerFgDark = Color(0xFFF87171);
  static const Color dangerBorderDark = Color(0xFF7F1D1D);

  // Energy Badge Border Accents (Light Mode)
  static const Color energyLowBorder = Color(0xFFA7D7BE);
  static const Color energyMediumBorder = Color(0xFFF6C3A6);
  static const Color energyDeepBorder = Color(0xFFC7CDFA);
  static const Color energyCreativeBorder = Color(0xFFFDE68A);
  static const Color energyAdminBorder = Color(0xFFD8D2C4);

  // High-Contrast Pill Text Colors (Light Mode Selected State)
  static const Color energyLowAccentText = Color(0xFF047857);
  static const Color energyMediumAccentText = Color(0xFFB45309);
  static const Color energyDeepAccentText = Color(0xFF6D28D9);
  static const Color energySkyAccentText = Color(0xFF0369A1);
  static const Color energyBlueAccentText = Color(0xFF1D4ED8);

  // Interactive Surface & Container Tokens
  static const Color darkInputBg = Color(0xFF1B2520);
  static const Color darkInputBorder = Color(0xFF2E4536);
  static const Color darkSheetBgAlt = Color(0xFF1E2638);
  static const Color darkSurfaceCardMuted = Color(0xFF161A26);
  static const Color darkSurfaceHover = Color(0xFF1E242C);
  static const Color lightSurfaceHover = Color(0xFFD6DCCF);
  static const Color lightHoverAlt = Color(0xFFECE7DE);
  static const Color darkHeaderPillBg = Color(0xFF11221A);
  static const Color darkHeaderPillBorder = Color(0xFF1F3D2E);
  static const Color darkAccountTileBg = Color(0xFF101713);
  static const Color darkActionBubbleBg = Color(0xFF161A23);
  static const Color darkActionBubbleBorder = Color(0xFF2E3648);

  // AI Feature Accents
  static const Color aiAccentViolet = Color(0xFF6366F1);
  static const Color aiAccentVioletLight = Color(0xFF818CF8);
  static const Color aiAccentVioletSubtle = Color(0xFFA5B4FC);

  // Neutral Shadow Colors
  static const Color shadowSlate = Color(0xFF0F172A);
  static const Color shadowForest = Color(0xFF1A241E);

  // Wear OS OLED Palette Tokens
  static const Color wearableOledBg = Color(0xFF000000);
  static const Color wearableSurfaceDark = Color(0xFF141916);
  static const Color wearableSurfaceDarkAlt = Color(0xFF141A16);
  static const Color wearableSurfaceCard = Color(0xFF1B1D1C);
  static const Color wearableSurfaceInput = Color(0xFF1E211F);
  static const Color wearableSurfaceActive = Color(0xFF1A211D);
  static const Color wearableSurfaceHeader = Color(0xFF161817);
  static const Color wearableSurfaceChip = Color(0xFF191B1A);

  // Action Accents (Top) - Dark Mode
  static const Color darkActionSyncBg = Color(0xFF193836);
  static const Color darkActionSyncFg = Color(0xFF5EEAD4);
  static const Color darkActionThemeBg = Color(0xFF362C1C);
  static const Color darkActionThemeFg = Color(0xFFFBBF24);

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
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentSage = Color(0xFF7E9A86);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  static const Color energyMediumFlow = Color(0xFF0284C7);
  static const Color energyAdministrative = Color(0xFF38BDF8);
  static const Color energyBlue = Color(0xFF2563EB);

  static const Map<String, Color> energyTagColors = {
    'low-friction': accentEmerald,
    'medium-flow': energyMediumFlow,
    'deep-focus': accentViolet,
    'creative': accentAmber,
    'administrative': energyAdministrative,
  };

  // Energy Badges (Balanced desaturated pastels)
  static const Color energyLowBg = Color(0xFFE7F4ED); // Soft sage / eucalyptus
  static const Color energyLowText = Color(0xFF166534); // Deep forest
  static const Color energyMediumBg =
      Color(0xFFFBE9DD); // Muted terra-cotta / apricot
  static const Color energyMediumText = Color(0xFF9A3412); // Warm mahogany
  static const Color energyDeepBg =
      Color(0xFFEEF0FB); // Soft periwinkle / lavender
  static const Color energyDeepText = Color(0xFF4338CA); // Indigo
  static const Color energyTimerBg = Color(0xFFEEF0FB); // Soft periwinkle
  static const Color energyTimerText = Color(0xFF4338CA);
  static const Color energyCreativeBg = Color(0xFFFEF3C7);
  static const Color energyCreativeText = Color(0xFFB45309);
  static const Color energyAdminBg = Color(0xFFF1ECE1);
  static const Color energyAdminText = Color(0xFF475569);

  // Border Radii
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(6));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusDeck = BorderRadius.all(Radius.circular(28));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999));

  // Pin Card Elevation Shadows
  static List<BoxShadow> get lightCardShadow => [
        BoxShadow(
          color: shadowForest.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadowForest.withValues(alpha: 0.07),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

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

  // ==========================================
  // Wear OS Smartwatch Palette Tokens (OLED Dark)
  // ==========================================
  /// Primary background for wearable cards, dialogs, and hero timers.
  static const Color wearableCardBg = Color(0xFF141916);

  /// Secondary surface background for compact wearable cards and text inputs.
  static const Color wearableCardSurface = Color(0xFF1E211F);

  /// Background container color for backlog pins on Wear OS.
  static const Color wearableCardBacklog = Color(0xFF1B1D1C);

  /// Background container color for completed pins on Wear OS.
  static const Color wearableCardDone = Color(0xFF141A16);

  /// Micro-step tile container background on Wear OS focus mode.
  static const Color wearableStepBg = Color(0xFF191B1A);

  /// Empty state container background on Wear OS.
  static const Color wearableEmptyBg = Color(0xFF161817);

  /// Status badge container background for wearable account card.
  static const Color wearableStatusBadgeBg = Color(0xFF1A211D);
}

