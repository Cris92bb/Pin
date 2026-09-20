import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Tactile interactive card for inactive stacked background tabs.
class LayeredDeckInactiveTab extends StatefulWidget {
  /// Status represented by this background tab.
  final TaskStatus status;

  /// Global task state for counting pins.
  final TaskListState state;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Border color for the tab.
  final Color borderColor;

  /// Background card color.
  final Color cardBg;

  /// Optional hover background color.
  final Color? hoverBg;

  /// Primary text color.
  final Color textPrimary;

  /// Tap callback to activate this deck.
  final VoidCallback onTap;

  /// Creates a [LayeredDeckInactiveTab].
  const LayeredDeckInactiveTab({
    super.key,
    required this.status,
    required this.state,
    required this.isDark,
    required this.borderColor,
    required this.cardBg,
    this.hoverBg,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  State<LayeredDeckInactiveTab> createState() => _LayeredDeckInactiveTabState();
}

class _LayeredDeckInactiveTabState extends State<LayeredDeckInactiveTab> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.status == TaskStatus.backlog
        ? widget.state.backlogTasks.length
        : (widget.status == TaskStatus.today
            ? widget.state.todayTasks.length
            : widget.state.doneTasks.length);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          alignment: Alignment.topCenter,
          scale: _isPressed ? 0.985 : (_isHovered ? 1.008 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.fromLTRB(18, 8, 16, 12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? (_isHovered ? PinTokens.darkSurfaceHover : widget.cardBg)
                  : (_isHovered
                      ? (widget.hoverBg ?? PinTokens.lightHoverAlt)
                      : widget.cardBg),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: _isHovered
                    ? (widget.isDark
                        ? PinTokens.darkBorder
                        : PinTokens.lightTextTertiary)
                    : widget.borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isDark ? Colors.black : PinTokens.shadowSlate)
                      .withValues(
                          alpha: _isHovered
                              ? (widget.isDark ? 0.12 : 0.07)
                              : (widget.isDark ? 0.08 : 0.04)),
                  blurRadius: _isHovered ? 8 : 4,
                  offset: Offset(0, _isHovered ? -3 : -2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                    )),
                    child: child,
                  ),
                );
              },
              child: Row(
                key: ValueKey('${widget.status.name}_$count'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                        color: _isHovered
                            ? widget.textPrimary
                            : (widget.isDark
                                ? PinTokens.darkTextSecondary
                                : PinTokens.lightTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? PinTokens.darkCardBg
                          : PinTokens.lightTagBg,
                      borderRadius: PinTokens.radiusFull,
                      border: widget.isDark
                          ? Border.all(color: PinTokens.darkBorder, width: 1.0)
                          : null,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? PinTokens.darkTextSecondary
                            : PinTokens.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
