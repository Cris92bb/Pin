import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utilities for detecting and adapting UI to smartwatch / Wear OS form factors.
class WearableUtils {
  /// Maximum logical width or height (shortest side) considered a smartwatch display.
  static const double maxWatchShortestSide = 320.0;

  /// Returns true if current viewport corresponds to a smartwatch/wearable screen.
  static bool isWearable(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide <= maxWatchShortestSide && size.shortestSide > 0;
  }

  /// Calculates safe inset padding so content does not clip on circular watch displays.
  static EdgeInsets getSafeCircularPadding(BuildContext context, {double extra = 8.0}) {
    final size = MediaQuery.sizeOf(context);
    final side = size.shortestSide;
    // For a circle of diameter D, inset to the largest inscribed rectangle:
    // (D - D / sqrt(2)) / 2 approx 0.1464 * D
    final inset = (side * 0.14) + extra;
    return EdgeInsets.symmetric(
      horizontal: math.max(16.0, inset),
      vertical: math.max(16.0, inset),
    );
  }
}
