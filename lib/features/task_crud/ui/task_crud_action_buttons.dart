import 'package:flutter/material.dart';
import '../../../shared/ui/pin_button.dart';

/// Bottom action buttons (Cancel and Save/Pin) for TaskCrudModal.
class TaskCrudActionButtons extends StatelessWidget {
  /// Whether editing an existing task.
  final bool isEditing;

  /// Cancel callback.
  final VoidCallback onCancel;

  /// Submit callback.
  final VoidCallback onSubmit;

  /// Creates a [TaskCrudActionButtons].
  const TaskCrudActionButtons({
    super.key,
    required this.isEditing,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PinButton(
          text: 'Cancel',
          onPressed: onCancel,
        ),
        const SizedBox(width: 10),
        PinButton.primary(
          text: isEditing ? 'Save Changes' : 'Pin to Deck',
          icon: isEditing ? Icons.check_rounded : Icons.push_pin_rounded,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
