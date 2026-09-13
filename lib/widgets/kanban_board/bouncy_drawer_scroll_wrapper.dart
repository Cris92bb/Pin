import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Wraps scrollable drawer content to provide an Apple-style tactile spring bounce
/// when scrolling reaches the end (both top and bottom boundaries) across mouse wheel,
/// trackpad, and touch/mouse drag gestures.
class BouncyDrawerScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController controller;

  const BouncyDrawerScrollWrapper({
    super.key,
    required this.child,
    required this.controller,
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
      duration: const Duration(milliseconds: 340),
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

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;
    final delta = event.scrollDelta.dy;

    // Check if at boundary and scrolling further past the scroll end
    final atTop = position.pixels <= position.minScrollExtent && delta < 0;
    final atBottom = position.pixels >= position.maxScrollExtent && delta > 0;

    if (atTop || atBottom) {
      // Apply rubber-band damping resistance
      const resistance = 0.28;
      final newOverscroll =
          (_overscroll - delta * resistance).clamp(-36.0, 36.0);

      _bounceController.stop();
      setState(() {
        _overscroll = newOverscroll;
      });

      // Spring overshoot rebound settling to 0
      _bounceAnimation = Tween<double>(
        begin: _overscroll,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: const Cubic(0.175, 0.885, 0.32, 1.275),
        ),
      );
      _bounceController.forward(from: 0.0);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (_overscroll != 0.0 && !_bounceController.isAnimating) {
        _bounceAnimation = Tween<double>(
          begin: _overscroll,
          end: 0.0,
        ).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: const Cubic(0.175, 0.885, 0.32, 1.275),
          ),
        );
        _bounceController.forward(from: 0.0);
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
