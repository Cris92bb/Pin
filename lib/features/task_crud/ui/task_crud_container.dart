import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Outer container wrapper for TaskCrudModal (supporting inline or popup Dialog mode).
class TaskCrudContainer extends StatelessWidget {
  /// The modal content body.
  final Widget child;

  /// Whether to display as a popup dialog.
  final bool asDialog;

  /// Creates a [TaskCrudContainer].
  const TaskCrudContainer({
    super.key,
    required this.child,
    required this.asDialog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final modalBg = isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

    if (!asDialog) {
      return Container(
        decoration: BoxDecoration(
          color: modalBg,
          borderRadius: PinTokens.radiusDeck,
          border: Border.all(color: borderColor, width: isDark ? 1.5 : 1.0),
        ),
        child: child,
      );
    }

    return Dialog(
      backgroundColor: modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusDeck,
        side: BorderSide(color: borderColor, width: isDark ? 1.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: child,
      ),
    );
  }
}
