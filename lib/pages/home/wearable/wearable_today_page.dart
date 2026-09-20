import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wearable_task_cards.dart';

/// The Today page of the Wear OS carousel view.
///
/// Displays the active in-progress workload up to the configured WIP limit.
class WearableTodayPage extends ConsumerWidget {
  /// State containing the current tasks and WIP limits.
  final TaskListState taskState;

  /// Safe circular insets to prevent clipping on round watch faces.
  final EdgeInsets safePadding;

  /// Creates a [WearableTodayPage] with [taskState] and [safePadding].
  const WearableTodayPage({
    super.key,
    required this.taskState,
    required this.safePadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = taskState.todayTasks;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: safePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PinTokens.accentSage.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PinTokens.accentSage.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'TODAY ${todayTasks.length}/${taskState.wipLimit}',
                  style: const TextStyle(
                    color: PinTokens.accentSage,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todayTasks.isEmpty)
            const WearableEmptyCard(
              title: 'No tasks for today',
              subtitle: 'Swipe left for Backlog',
            )
          else ...[
            // Hero Top Task Card
            WearableHeroTaskCard(task: todayTasks.first),
            // Remaining today tasks
            for (final task in todayTasks.skip(1)) ...[
              const SizedBox(height: 6),
              WearableCompactTaskCard(task: task),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
