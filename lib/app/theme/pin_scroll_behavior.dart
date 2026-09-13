import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Tight, tactile bouncy scroll physics that strictly caps overscroll to a subtle
/// bumper limit (default 10.0px) and snaps back quickly with a stiff spring,
/// preventing the unsightly large empty voids of default BouncingScrollPhysics.
class TightBouncingScrollPhysics extends BouncingScrollPhysics {
  final double maxOverscroll;

  const TightBouncingScrollPhysics({
    super.parent,
    this.maxOverscroll = 10.0,
  });

  @override
  TightBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TightBouncingScrollPhysics(
      parent: buildParent(ancestor),
      maxOverscroll: maxOverscroll,
    );
  }

  @override
  double frictionFactor(double overscrollFraction) =>
      0.10 * math.pow(1.0 - overscrollFraction.clamp(0.0, 1.0), 2);

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    assert(position.minScrollExtent <= position.maxScrollExtent);

    final min = position.minScrollExtent - maxOverscroll;
    final max = position.maxScrollExtent + maxOverscroll;

    if (value < position.pixels && position.pixels <= min) {
      return value - position.pixels;
    }
    if (value < min && min < position.pixels) {
      return value - min;
    }

    if (max <= position.pixels && position.pixels < value) {
      return value - position.pixels;
    }
    if (position.pixels < max && max < value) {
      return value - max;
    }

    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    if (position.outOfRange) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }
      assert(end != null);
      return ScrollSpringSimulation(
        const SpringDescription(
          mass: 0.5,
          stiffness: 400.0,
          damping: 24.0,
        ),
        position.pixels,
        end!,
        velocity,
        tolerance: tolerance,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

/// Custom ScrollBehavior providing tight, responsive bouncy spring physics
/// across all scrollable views (Focus Mode, Settings, Modals, Kanban Drawers)
/// and enabling drag scrolling across touch, trackpad, mouse, and stylus.
class PinScrollBehavior extends MaterialScrollBehavior {
  const PinScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const TightBouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
