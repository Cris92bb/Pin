import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Active drawer header with drawer pull grip, WIP indicators, and swipe gestures.
class LayeredDeckHeader extends ConsumerWidget {
  /// Active deck status.
  final TaskStatus activeDeck;

  /// Global task list state.
  final TaskListState state;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Primary text color.
  final Color textPrimary;

  /// Callback when user swipes left or right.
  final ValueChanged<int> onNavigateDrawer;

  /// Creates a [LayeredDeckHeader].
  const LayeredDeckHeader({
    super.key,
    required this.activeDeck,
    required this.state,
    required this.isDark,
    required this.textPrimary,
    required this.onNavigateDrawer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tactile Drawer Pull Grip Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 2),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? PinTokens.darkTextTertiary
                  : PinTokens.lightTextTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Active Deck Header with swipe gestures
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              onNavigateDrawer(1);
            } else if (details.primaryVelocity! > 200) {
              onNavigateDrawer(-1);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row: e.g. "To do", "MAX 5 FOCUS", "3/5"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              activeDeck.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // MAX 5 FOCUS pill for Today
                          if (activeDeck == TaskStatus.today)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? PinTokens.darkMaxFocusBg
                                    : PinTokens.lightMaxFocusBg,
                                borderRadius: PinTokens.radiusFull,
                              ),
                              child: Text(
                                'MAX ${state.wipLimit} FOCUS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? PinTokens.darkMaxFocusText
                                      : PinTokens.lightMaxFocusText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Count Pill (e.g. 3/5 or 4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? PinTokens.darkFabBg : PinTokens.lightFabBg,
                        borderRadius: PinTokens.radiusFull,
                        border: isDark
                            ? Border.all(
                                color: PinTokens.darkBorder, width: 1.0)
                            : null,
                      ),
                      child: Text(
                        activeDeck == TaskStatus.today
                            ? '${state.todayCount}/${state.wipLimit}'
                            : (activeDeck == TaskStatus.backlog
                                ? '${state.backlogTasks.length}'
                                : '${state.doneTasks.length}'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? PinTokens.darkTextPrimary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Sub-header WIP Indicator row (only on Today deck)
                if (activeDeck == TaskStatus.today) ...[
                  Row(
                    children: [
                      // Visual Slot Pills (■ ■ ■ □ □)
                      Row(
                        children: List.generate(state.wipLimit, (index) {
                          final isFilled = index < state.todayCount;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 18,
                            height: 7,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? (isDark
                                      ? PinTokens.darkTextPrimary
                                      : PinTokens.lightFabBg)
                                  : (isDark
                                      ? PinTokens.darkBorder
                                      : PinTokens.lightBorder),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const Spacer(),

                      // Available slots label
                      Text(
                        '${state.availableSlots} slots available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? PinTokens.darkTextSecondary
                              : PinTokens.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ] else if (activeDeck == TaskStatus.done &&
                    state.doneTasks.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: PinTokens.radiusSm,
                      onTap: () {
                        ref.read(taskStateProvider.notifier).clearDoneTasks();
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        child: Text(
                          'Clear Archive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PinTokens.accentRose,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
