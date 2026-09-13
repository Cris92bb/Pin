import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom ScrollBehavior providing fluid Apple-style bouncy spring physics
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
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
