import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/sync/state/sync_controller.dart';
import '../../shared/ui/pin_tokens.dart';
import '../../shared/ui/wearable_utils.dart';
import 'wearable/left_only_scroll_physics.dart';
import 'wearable/wearable_account_page.dart';
import 'wearable/wearable_backlog_page.dart';
import 'wearable/wearable_done_page.dart';
import 'wearable/wearable_focus_view.dart';
import 'wearable/wearable_today_page.dart';

export 'wearable/left_only_scroll_physics.dart';
export 'wearable/wearable_focus_view.dart';

/// Optimized, glanceable smartwatch interface for Pin.
///
/// Designed specifically for circular and square Wear OS screens.
/// Features infinite leftward carousel navigation across 4 core pages:
/// Today, Backlog, Completed, and Account.
class WearableHomePage extends ConsumerStatefulWidget {
  /// Creates a new instance of [WearableHomePage].
  const WearableHomePage({super.key});

  @override
  ConsumerState<WearableHomePage> createState() => _WearableHomePageState();
}

class _WearableHomePageState extends ConsumerState<WearableHomePage> {
  static const int _kPageCount = 4;
  static const int _kInitialPage = 1000 * _kPageCount; // 4000
  late final PageController _pageController;
  int _currentPage = _kInitialPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kInitialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int targetModIndex) {
    final currentMod = _currentPage % _kPageCount;
    int diff = (targetModIndex - currentMod) % _kPageCount;
    if (diff < 0) diff += _kPageCount;
    if (diff > 0) {
      _pageController.animateToPage(
        _currentPage + diff,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFocus = ref.watch(activeFocusTaskProvider);
    final taskState = ref.watch(taskStateProvider);
    final syncState = ref.watch(syncControllerProvider);

    // If focus mode is active, directly render the dedicated watch focus view
    if (activeFocus != null) {
      return WearableFocusView(
        task: activeFocus,
        onExit: () {
          ref.read(activeFocusTaskProvider.notifier).state = null;
        },
      );
    }

    final safePadding =
        WearableUtils.getSafeCircularPadding(context, extra: 4);
    // Use the full width of the screen on the watch with safe top/bottom margins for circular clipping
    final fullWidthPadding = EdgeInsets.fromLTRB(
      6.0,
      safePadding.top,
      6.0,
      safePadding.bottom + 8.0,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const LeftOnlyPageScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                final normalizedIndex =
                    (index % _kPageCount + _kPageCount) % _kPageCount;
                switch (normalizedIndex) {
                  case 0:
                    return WearableTodayPage(
                      taskState: taskState,
                      safePadding: fullWidthPadding,
                    );
                  case 1:
                    return WearableBacklogPage(
                      taskState: taskState,
                      safePadding: fullWidthPadding,
                    );
                  case 2:
                    return WearableDonePage(
                      taskState: taskState,
                      safePadding: fullWidthPadding,
                    );
                  case 3:
                  default:
                    return WearableAccountPage(
                      syncState: syncState,
                      safePadding: fullWidthPadding,
                    );
                }
              },
            ),
            // Page indicator dots at top
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_kPageCount, (index) {
                  final activeIndex =
                      (_currentPage % _kPageCount + _kPageCount) % _kPageCount;
                  final isActive = index == activeIndex;
                  return GestureDetector(
                    onTap: () => _goToPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isActive ? 12 : 5,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? PinTokens.accentSage
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
