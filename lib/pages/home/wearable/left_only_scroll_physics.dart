import 'package:flutter/material.dart';

/// Custom scroll physics that only permits leftward dragging (advancing forward)
/// and strictly blocks rightward drags (which conflict with Wear OS system back/dismiss gestures).
class LeftOnlyPageScrollPhysics extends PageScrollPhysics {
  /// Creates an instance of [LeftOnlyPageScrollPhysics].
  const LeftOnlyPageScrollPhysics({super.parent});

  @override
  LeftOnlyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LeftOnlyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // offset > 0 means dragging finger towards right (attempting to scroll backwards)
    if (offset > 0) {
      return 0.0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Prevent any scrolling backwards towards lower pixel values
    if (value < position.pixels) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // Clamp any backward velocity to zero so it snaps in place instead of moving backward
    if (velocity > 0) {
      return super.createBallisticSimulation(position, 0);
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
