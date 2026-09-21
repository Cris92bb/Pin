import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import 'breakdown_engine_badge.dart';

/// Header widget for the AI Task Breakdown modal dialog, featuring
/// the title, icon, close button, and engine indicator badge.
class BreakdownModalHeader extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool isLocalOnDevice;
  final String? engineTitle;
  final Duration? duration;
  final VoidCallback? onOpenSettings;
  final VoidCallback onClose;

  const BreakdownModalHeader({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.isLocalOnDevice,
    this.engineTitle,
    this.duration,
    this.onOpenSettings,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: isDark ? PinTokens.darkEnergyLowText : PinTokens.lightActiveFocus,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI Breakdown & Re-Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (!isLoading && errorMessage == null) ...[
                const SizedBox(height: 6),
                BreakdownEngineBadge(
                  isLocalOnDevice: isLocalOnDevice,
                  engineName: engineTitle,
                  duration: duration,
                ),
              ],
            ],
          ),
        ),
        if (onOpenSettings != null) ...[
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            tooltip: 'AI Settings',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 18,
            onPressed: onOpenSettings,
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: 'Close',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 18,
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// Action buttons in the footer of the AI Task Breakdown modal.
class BreakdownModalActions extends StatelessWidget {
  final VoidCallback onOpenFullEditor;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const BreakdownModalActions({
    super.key,
    required this.onOpenFullEditor,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton(
          onPressed: onOpenFullEditor,
          child: const Text('Open Full Editor', style: TextStyle(fontSize: 12)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PinButton(
              text: 'Cancel',
              variant: PinButtonVariant.secondary,
              onPressed: onCancel,
            ),
            const SizedBox(width: 8),
            PinButton(
              text: 'Apply to Pin',
              icon: Icons.check_rounded,
              onPressed: onApply,
            ),
          ],
        ),
      ],
    );
  }
}
