import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wide_fold_helpers.dart';

/// Empty state presentation for active Kanban drawers.
class WideFoldEmptyState extends StatelessWidget {
  /// The task status of the empty drawer.
  final TaskStatus status;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldEmptyState].
  const WideFoldEmptyState({
    super.key,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    final message = status == TaskStatus.today
        ? 'No pins for Today.\nPull a task from Backlog or capture a new one!'
        : (status == TaskStatus.done
            ? 'No completed tasks yet.\nFinish active pins to see them here!'
            : 'Backlog is clear.\nAll ideas organized!');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              WideFoldHelpers.statusIcon(status),
              size: 36,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
