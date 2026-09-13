import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Wraps scrollable drawer content to provide a tight, crisp tactile spring bounce
/// when scrolling reaches the end (both top and bottom boundaries) across mouse wheel,
/// trackpad, and touch/mouse drag gestures, avoiding long empty spaces.
class BouncyDrawerScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double maxOverscroll;
  final Duration duration;

  const BouncyDrawerScrollWrapper({
    super.key,
    required this.child,
    required this.controller,
    this.maxOverscroll = 10.0,
    this.duration = const Duration(milliseconds: 160),
  });

  @override
  State<BouncyDrawerScrollWrapper> createState() =>
      _BouncyDrawerScrollWrapperState();
}

class _BouncyDrawerScrollWrapperState extends State<BouncyDrawerScrollWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  Animation<double>? _bounceAnimation;
  double _overscroll = 0.0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        if (_bounceAnimation != null) {
          setState(() {
            _overscroll = _bounceAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _animateBack() {
    _bounceController.stop();
    _bounceAnimation = Tween<double>(
      begin: _overscroll,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: const Cubic(0.2, 0.9, 0.3, 1.15),
      ),
    );
    _bounceController.forward(from: 0.0);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;
    final delta = event.scrollDelta.dy;

    // Check if at boundary and scrolling further past the scroll end
    final atTop = position.pixels <= position.minScrollExtent && delta < 0;
    final atBottom = position.pixels >= position.maxScrollExtent && delta > 0;

    if (atTop || atBottom) {
      // Stiff damping resistance for a tight, crisp tactile bumper
      const resistance = 0.08;
      final newOverscroll = (_overscroll - delta * resistance)
          .clamp(-widget.maxOverscroll, widget.maxOverscroll);

      setState(() {
        _overscroll = newOverscroll;
      });
      _animateBack();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      // Dragging past boundary: subtle damped overscroll without long gap
      if (notification.dragDetails != null) {
        final delta = notification.overscroll;
        const resistance = 0.12;
        final newOverscroll = (_overscroll - delta * resistance)
            .clamp(-widget.maxOverscroll, widget.maxOverscroll);
        _bounceController.stop();
        setState(() {
          _overscroll = newOverscroll;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_overscroll != 0.0) {
        _animateBack();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Transform.translate(
          offset: Offset(0, _overscroll),
          child: widget.child,
        ),
      ),
    );
  }
}
