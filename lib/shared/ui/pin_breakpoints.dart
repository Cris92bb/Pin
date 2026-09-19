import 'package:flutter/material.dart';
import 'wearable_utils.dart';

/// Semantic viewport tiers for Pin across Watch, Smartphone, Foldable, and Web.
enum PinScreenTier {
  /// Smartwatches / Wear OS (circular or compact square displays)
  xs,

  /// Smartphones, Foldable devices (folded), and compact Web/Desktop windows
  small,

  /// Foldable devices (unfolded), Tablets, Desktop, and wide Web windows
  wide,
}

/// Canonical responsive breakpoints for Pin.
class PinBreakpoints {
  const PinBreakpoints._();

  /// Upper bound for XS (smartwatch / Wear OS)
  static const double xsMax = 320.0;

  /// Threshold dividing single-drawer Smartphone/Fold-folded (small) from 3-drawer Fold-unfolded/Web (wide)
  static const double smallMax = 720.0;

  /// Max content width for wide layouts
  static const double wideMaxWidth = 1240.0;

  /// Resolves the current screen tier from context.
  static PinScreenTier getTier(BuildContext context) {
    if (WearableUtils.isWearable(context)) {
      return PinScreenTier.xs;
    }
    final width = MediaQuery.of(context).size.width;
    if (width < xsMax) {
      return PinScreenTier.xs;
    }
    if (width < smallMax) {
      return PinScreenTier.small;
    }
    return PinScreenTier.wide;
  }

  /// Whether current viewport is in wide mode (Fold unfolded, Web, Desktop)
  static bool isWide(BuildContext context) =>
      getTier(context) == PinScreenTier.wide;

  /// Whether current viewport is in small mode (Smartphone, Fold folded, narrow Web)
  static bool isSmall(BuildContext context) =>
      getTier(context) == PinScreenTier.small;

  /// Whether current viewport is in xs mode (Watch / Wear OS)
  static bool isXs(BuildContext context) =>
      getTier(context) == PinScreenTier.xs;
}
