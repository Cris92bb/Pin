import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wearable_task_cards.dart';

/// The Completed page of the Wear OS carousel view.
///
/// Displays finished pins with strikethrough typography and success indicators.
class WearableDonePage extends ConsumerWidget {
  /// State containing the current tasks.
  final TaskListState taskState;

  /// Safe circular insets to prevent clipping on round watch faces.
  final EdgeInsets safePadding;

  /// Creates a [WearableDonePage] with [taskState] and [safePadding].
  const WearableDonePage({
    super.key,
    required this.taskState,
    required this.safePadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneTasks = taskState.doneTasks;

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
                  color: PinTokens.accentEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'COMPLETED (${doneTasks.length})',
                  style: const TextStyle(
                    color: PinTokens.accentEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (doneTasks.isEmpty)
            const WearableEmptyCard(
              title: 'No finished pins',
              subtitle: 'Swipe left for Account',
            )
          else ...[
            for (final task in doneTasks.take(10)) ...[
              Builder(
                builder: (context) {
                  final hasDescription = task.description.trim().isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: PinTokens.wearableCardDone,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle,
                              size: 13, color: PinTokens.accentEmerald),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
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
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 9.5,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.18,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
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
