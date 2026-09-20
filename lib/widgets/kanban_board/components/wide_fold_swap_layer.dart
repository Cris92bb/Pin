import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wide_fold_active_drawer.dart';
import 'wide_fold_docking_tray.dart';
import 'wide_fold_inactive_drawer.dart';

/// Layer orchestrating the 3 Kanban drawers and cross-screen physical swap animations.
///
/// Architecture & Role:
/// - Layer: `widgets/kanban_board/components` (Feature-Sliced Design v2.1)
/// - In idle state: displays the active drawer and 2 inactive drawers side-by-side.
/// - During swap: animates the departing drawer into the target slot, renders the docking
///   tray underneath, keeps the untouched inactive drawer stationary, and glides the arriving
///   drawer into the active position elevated with drop shadows.
class WideFoldSwapLayer extends StatelessWidget {
  /// Progress of the drawer swap animation (0.0 to 1.0).
  final double progress;

  /// Whether a drawer swap animation is currently active.
  final bool isAnimating;

  /// Width of the primary active column.
  final double activeWidth;

  /// Width of each inactive drawer card.
  final double inactiveCardWidth;

  /// Left coordinate of slot 0 in the inactive section.
  final double slot0Left;

  /// Left coordinate of slot 1 in the inactive section.
  final double slot1Left;

  /// Index of the inactive slot being swapped (0 or 1).
  final int swappingSlotIndex;

  /// Currently active status.
  final TaskStatus activeStatus;

  /// Status of the active drawer departing during transition.
  final TaskStatus? departingStatus;

  /// Status of the inactive drawer arriving into active position.
  final TaskStatus? arrivingStatus;

  /// List of inactive statuses (2 elements).
  final List<TaskStatus> inactiveStatuses;

  /// Global task list state.
  final TaskListState taskState;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Scroll controller for the active drawer.
  final ScrollController scrollController;

  /// Callback when an inactive drawer is tapped, passing status and slot index.
  final void Function(TaskStatus status, int slotIndex) onSelectSlot;

  /// Creates a [WideFoldSwapLayer].
  const WideFoldSwapLayer({
    super.key,
    required this.progress,
    required this.isAnimating,
    required this.activeWidth,
    required this.inactiveCardWidth,
    required this.slot0Left,
    required this.slot1Left,
    required this.swappingSlotIndex,
    required this.activeStatus,
    required this.departingStatus,
    required this.arrivingStatus,
    required this.inactiveStatuses,
    required this.taskState,
    required this.isDark,
    required this.scrollController,
    required this.onSelectSlot,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAnimating) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Active Drawer on the left
          Positioned(
            left: 0,
            top: 0,
            width: activeWidth,
            bottom: 0,
            child: WideFoldActiveDrawer(
              status: activeStatus,
              taskState: taskState,
              isDark: isDark,
              scrollController: scrollController,
            ),
          ),

          // Inactive Drawer Slot 0
          Positioned(
            left: slot0Left,
            top: 0,
            width: inactiveCardWidth,
            bottom: 0,
            child: WideFoldInactiveDrawer(
              status: inactiveStatuses[0],
              taskState: taskState,
              isDark: isDark,
              onSelect: () => onSelectSlot(inactiveStatuses[0], 0),
            ),
          ),

          // Inactive Drawer Slot 1
          Positioned(
            left: slot1Left,
            top: 0,
            width: inactiveCardWidth,
            bottom: 0,
            child: WideFoldInactiveDrawer(
              status: inactiveStatuses[1],
              taskState: taskState,
              isDark: isDark,
              onSelect: () => onSelectSlot(inactiveStatuses[1], 1),
            ),
          ),
        ],
      );
    }

    // Active drawer swap in motion
    final targetSlotLeft = swappingSlotIndex == 0 ? slot0Left : slot1Left;
    final otherSlotIndex = swappingSlotIndex == 0 ? 1 : 0;
    final otherSlotLeft = swappingSlotIndex == 0 ? slot1Left : slot0Left;
    final otherSlotStatus = inactiveStatuses[otherSlotIndex];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Untouched Inactive Drawer stays rock solid
        Positioned(
          left: otherSlotLeft,
          top: 0,
          width: inactiveCardWidth,
          bottom: 0,
          child: WideFoldInactiveDrawer(
            status: otherSlotStatus,
            taskState: taskState,
            isDark: isDark,
            onSelect: () => onSelectSlot(otherSlotStatus, otherSlotIndex),
          ),
        ),

        // 2. Docking Tray in swapped slot
        Positioned(
          left: targetSlotLeft,
          top: 0,
          width: inactiveCardWidth,
          bottom: 0,
          child: WideFoldDockingTray(isDark: isDark),
        ),

        // 3. Departing Drawer (glides right into target slot)
        if (departingStatus != null)
          Positioned(
            left: 0,
            top: 0,
            width: inactiveCardWidth,
            bottom: 0,
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(targetSlotLeft * progress, 0),
                child: WideFoldInactiveDrawer(
                  status: departingStatus!,
                  taskState: taskState,
                  isDark: isDark,
                ),
              ),
            ),
          ),

        // 4. Arriving Drawer (glides left into active column, elevated ON TOP)
        if (arrivingStatus != null)
          Positioned(
            left: 0,
            top: 0,
            width: activeWidth,
            bottom: 0,
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(targetSlotLeft * (1.0 - progress), 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: PinTokens.radiusDeck,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : PinTokens.shadowSlate)
                            .withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(-6, 8),
                      ),
                    ],
                  ),
                  child: WideFoldActiveDrawer(
                    status: arrivingStatus!,
                    taskState: taskState,
                    isDark: isDark,
                    scrollController: scrollController,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
