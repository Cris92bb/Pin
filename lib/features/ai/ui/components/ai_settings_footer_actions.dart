import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_button.dart';

/// Footer action buttons for the AI Settings modal (Test connection, Cancel, Save).
class AiSettingsFooterActions extends StatelessWidget {
  final bool isTesting;
  final VoidCallback onTestCloud;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const AiSettingsFooterActions({
    super.key,
    required this.isTesting,
    required this.onTestCloud,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: isTesting ? null : onTestCloud,
          child: isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test', style: TextStyle(fontSize: 12)),
        ),
        Row(
          children: [
            PinButton(
              text: 'Cancel',
              variant: PinButtonVariant.secondary,
              onPressed: onCancel,
            ),
            const SizedBox(width: 8),
            PinButton(
              text: 'Save',
              icon: Icons.check_rounded,
              onPressed: onSave,
            ),
          ],
        ),
      ],
    );
  }
}
