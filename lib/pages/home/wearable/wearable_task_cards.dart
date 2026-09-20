import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Prominent hero task card displayed at the top of the Today watch view.
///
/// Features 2-line title, 3-line description, completion quick action,
/// and a full-width 'START FOCUS' interactive button.
class WearableHeroTaskCard extends ConsumerWidget {
  /// The task displayed within the hero card.
  final PinTask task;

  /// Creates a [WearableHeroTaskCard] for the given [task].
  const WearableHeroTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDescription = task.description.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: PinTokens.wearableCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PinTokens.accentSage.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description.trim(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9.5,
                          height: 1.2,
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
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.check_circle_outline,
                    color: PinTokens.accentEmerald),
                tooltip: 'Complete',
                onPressed: () {
                  ref.read(taskStateProvider.notifier).moveToDone(task.id);
                },
              ),
            ],
          ),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${task.completedSubtasksCount}/${task.totalSubtasksCount} steps completed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PinTokens.accentSage,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text(
                'START FOCUS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () {
                ref.read(activeFocusTaskProvider.notifier).state = task;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact task card row displayed for secondary Today tasks on Wear OS.
class WearableCompactTaskCard extends ConsumerWidget {
  /// The task to render.
  final PinTask task;

  /// Creates a [WearableCompactTaskCard] for [task].
  const WearableCompactTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDescription = task.description.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: PinTokens.wearableCardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
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
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(activeFocusTaskProvider.notifier).state = task;
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PinTokens.accentSage.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  size: 14, color: PinTokens.accentSage),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(taskStateProvider.notifier).moveToDone(task.id);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PinTokens.accentEmerald.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 14, color: PinTokens.accentEmerald),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile empty state card displayed when a watch list has no tasks.
class WearableEmptyCard extends StatelessWidget {
  /// Primary headline message.
  final String title;

  /// Secondary guidance sub-caption.
  final String subtitle;

  /// Creates a [WearableEmptyCard] with [title] and [subtitle].
  const WearableEmptyCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: PinTokens.wearableEmptyBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 24, color: PinTokens.accentSage),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
