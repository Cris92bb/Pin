import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// A soft docking tray outline rendered underneath a transitioning card slot in WideFoldKanbanView.
///
/// Gives a physical visual cue of the docking slot where a card is departing
/// from or arriving into during cross-screen drawer swap animations.
class WideFoldDockingTray extends StatelessWidget {
  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldDockingTray].
  const WideFoldDockingTray({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg =
        isDark ? PinTokens.darkStackedTabBg : PinTokens.lightStackedTabBg;

    return Container(
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.35),
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
    );
  }
}
