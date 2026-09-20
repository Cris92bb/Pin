import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../bouncy_drawer_scroll_wrapper.dart';
import 'layered_deck_transitions.dart';

/// Tactile scrollable list for the active drawer with bouncy physics and cascading task reveal.
class LayeredDeckTaskList extends StatefulWidget {
  /// The list of tasks in the active drawer.
  final List<PinTask> tasks;

  /// The status of the active drawer.
  final TaskStatus activeDeck;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Secondary text color.
  final Color textSecondary;

  /// Creates a [LayeredDeckTaskList].
  const LayeredDeckTaskList({
    super.key,
    required this.tasks,
    required this.activeDeck,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  State<LayeredDeckTaskList> createState() => _LayeredDeckTaskListState();
}

class _LayeredDeckTaskListState extends State<LayeredDeckTaskList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return BouncyDrawerScrollWrapper(
        controller: _scrollController,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.activeDeck == TaskStatus.today
                              ? Icons.bolt_rounded
                              : (widget.activeDeck == TaskStatus.done
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.inventory_2_outlined),
                          size: 38,
                          color: widget.isDark
                              ? PinTokens.darkTextMuted
                              : PinTokens.lightTextTertiary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.activeDeck == TaskStatus.today
                              ? 'No active Pins today.'
                              : (widget.activeDeck == TaskStatus.done
                                  ? 'No completed Pins yet.'
                                  : 'Backlog is empty.'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.activeDeck == TaskStatus.today
                              ? 'Pin up to 5 tasks from Backlog or tap + below.'
                              : 'Tap + to capture a new Pin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? PinTokens.darkTextMuted
                                : PinTokens.lightTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return BouncyDrawerScrollWrapper(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          return StaggeredTaskCard(
            key: ValueKey(task.id),
            index: index,
            task: task,
          );
        },
      ),
    );
  }
}
