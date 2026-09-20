import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wearable_task_cards.dart';

/// The Backlog page of the Wear OS carousel view.
///
/// Displays pending tasks with quick one-tap promotion to Today.
class WearableBacklogPage extends ConsumerWidget {
  /// State containing the current tasks.
  final TaskListState taskState;

  /// Safe circular insets to prevent clipping on round watch faces.
  final EdgeInsets safePadding;

  /// Creates a [WearableBacklogPage] with [taskState] and [safePadding].
  const WearableBacklogPage({
    super.key,
    required this.taskState,
    required this.safePadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backlogTasks = taskState.backlogTasks;

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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'BACKLOG (${backlogTasks.length})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (backlogTasks.isEmpty)
            const WearableEmptyCard(
              title: 'Backlog is empty',
              subtitle: 'Swipe left for Completed',
            )
          else ...[
            for (final task in backlogTasks) ...[
              Builder(
                builder: (context) {
                  final hasDescription = task.description.trim().isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: PinTokens.wearableCardBacklog,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasDescription) ...[
                                const SizedBox(height: 2),
                                Text(
                                  task.description.trim(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 9.5,
                                    height: 1.18,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 26, minHeight: 26),
                          icon: const Icon(Icons.north_rounded,
                              color: PinTokens.accentSage),
                          tooltip: 'Move to Today',
                          onPressed: () {
                            ref
                                .read(taskStateProvider.notifier)
                                .moveToToday(task.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
