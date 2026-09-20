import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../task_card.dart';

/// Animated widget translating child by an explicit logical pixel offset.
class PixelSlideTransition extends AnimatedWidget {
  /// The child widget to translate.
  final Widget child;

  /// Creates a [PixelSlideTransition].
  const PixelSlideTransition({
    super.key,
    required Animation<Offset> offset,
    required this.child,
  }) : super(listenable: offset);

  /// The offset animation driving translation.
  Animation<Offset> get offset => listenable as Animation<Offset>;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset.value,
      child: child,
    );
  }
}

/// Cascading staggered reveal wrapper for individual task cards.
class StaggeredTaskCard extends StatefulWidget {
  /// The visual index in the list for staggered timing.
  final int index;

  /// The task to display.
  final PinTask task;

  /// Creates a [StaggeredTaskCard].
  const StaggeredTaskCard({
    super.key,
    required this.index,
    required this.task,
  });

  @override
  State<StaggeredTaskCard> createState() => _StaggeredTaskCardState();
}

class _StaggeredTaskCardState extends State<StaggeredTaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(curve);

    final delayMs = (widget.index * 25).clamp(0, 150);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: TaskCard(
          task: widget.task,
        ),
      ),
    );
  }
}
