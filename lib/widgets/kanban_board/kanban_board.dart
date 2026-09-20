import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import 'kanban_column.dart';

/// The multi-column desktop canvas holding Backlog, Today, and Done.
class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskStateProvider);
    final notifier = ref.read(taskStateProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Backlog (Icebox) - Collapsible tray
                KanbanColumn(
                  title: 'Backlog (Icebox)',
                  icon: Icons.inventory_2_outlined,
                  status: TaskStatus.backlog,
                  tasks: state.backlogTasks,
                  isCollapsible: true,
                  initialCollapsed: false,
                ),

                // Today - Strict WIP queue
                KanbanColumn(
                  title: 'Today',
                  icon: Icons.bolt_rounded,
                  status: TaskStatus.today,
                  tasks: state.todayTasks,
                  isWipEnforced: true,
                  wipLimit: state.wipLimit,
                  isCollapsible: false,
                ),

                // Done - Finished tasks
                KanbanColumn(
                  title: 'Done',
                  icon: Icons.check_circle_outline_rounded,
                  status: TaskStatus.done,
                  tasks: state.doneTasks,
                  isCollapsible: true,
                  initialCollapsed: false,
                  onClear: () => notifier.clearDoneTasks(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
