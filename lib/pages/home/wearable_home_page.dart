import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/atomic_step.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/sync/model/sync_status.dart';
import '../../features/sync/state/sync_controller.dart';
import '../../shared/ui/pin_tokens.dart';
import '../../shared/ui/wearable_utils.dart';

/// Custom scroll physics that only permits leftward dragging (advancing forward)
/// and strictly blocks rightward drags (which conflict with Wear OS system back/dismiss gestures).
class LeftOnlyPageScrollPhysics extends PageScrollPhysics {
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

/// Optimized, glanceable smartwatch interface for Pin.
/// Designed specifically for circular and square Wear OS screens.
class WearableHomePage extends ConsumerStatefulWidget {
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

    final safePadding = WearableUtils.getSafeCircularPadding(context, extra: 4);
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
                    return _buildTodayPage(context, taskState, fullWidthPadding);
                  case 1:
                    return _buildBacklogPage(context, taskState, fullWidthPadding);
                  case 2:
                    return _buildDonePage(context, taskState, fullWidthPadding);
                  case 3:
                  default:
                    return _buildAccountPage(context, syncState, fullWidthPadding);
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

  Widget _buildTodayPage(
    BuildContext context,
    TaskListState taskState,
    EdgeInsets safePadding,
  ) {
    final todayTasks = taskState.todayTasks;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: safePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PinTokens.accentSage.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PinTokens.accentSage.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'TODAY ${todayTasks.length}/${taskState.wipLimit}',
                  style: const TextStyle(
                    color: PinTokens.accentSage,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todayTasks.isEmpty)
            _buildEmptyCard('No tasks for today', 'Swipe left for Backlog')
          else ...[
            // Hero Top Task Card
            _buildHeroTaskCard(todayTasks.first),
            // Remaining today tasks
            for (final task in todayTasks.skip(1)) ...[
              const SizedBox(height: 6),
              _buildCompactTaskCard(task),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeroTaskCard(PinTask task) {
    final hasDescription = task.description.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF141916),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PinTokens.accentSage.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description.trim(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9.5,
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.check_circle_outline, color: PinTokens.accentEmerald),
                tooltip: 'Complete',
                onPressed: () {
                  ref.read(taskStateProvider.notifier).moveToDone(task.id);
                },
              ),
            ],
          ),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${task.completedSubtasksCount}/${task.totalSubtasksCount} steps completed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PinTokens.accentSage,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text(
                'START FOCUS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () {
                ref.read(activeFocusTaskProvider.notifier).state = task;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTaskCard(PinTask task) {
    final hasDescription = task.description.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E211F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description.trim(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 9.5,
                      height: 1.18,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(activeFocusTaskProvider.notifier).state = task;
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PinTokens.accentSage.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, size: 14, color: PinTokens.accentSage),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(taskStateProvider.notifier).moveToDone(task.id);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PinTokens.accentEmerald.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 14, color: PinTokens.accentEmerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacklogPage(
    BuildContext context,
    TaskListState taskState,
    EdgeInsets safePadding,
  ) {
    final backlogTasks = taskState.backlogTasks;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: safePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'BACKLOG (${backlogTasks.length})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (backlogTasks.isEmpty)
            _buildEmptyCard('Backlog is empty', 'Swipe left for Completed')
          else ...[
            for (final task in backlogTasks) ...[
              Builder(
                builder: (context) {
                  final hasDescription = task.description.trim().isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D1C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasDescription) ...[
                                const SizedBox(height: 2),
                                Text(
                                  task.description.trim(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 9.5,
                                    height: 1.18,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: const Icon(Icons.north_rounded, color: PinTokens.accentSage),
                          tooltip: 'Move to Today',
                          onPressed: () {
                            ref.read(taskStateProvider.notifier).moveToToday(task.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDonePage(
    BuildContext context,
    TaskListState taskState,
    EdgeInsets safePadding,
  ) {
    final doneTasks = taskState.doneTasks;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: safePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PinTokens.accentEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'COMPLETED (${doneTasks.length})',
                  style: const TextStyle(
                    color: PinTokens.accentEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (doneTasks.isEmpty)
            _buildEmptyCard('No finished pins', 'Swipe left for Account')
          else ...[
            for (final task in doneTasks.take(10)) ...[
              Builder(
                builder: (context) {
                  final hasDescription = task.description.trim().isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle,
                              size: 13, color: PinTokens.accentEmerald),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasDescription) ...[
                                const SizedBox(height: 2),
                                Text(
                                  task.description.trim(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 9.5,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.18,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAccountPage(
    BuildContext context,
    SyncState syncState,
    EdgeInsets safePadding,
  ) {
    final isGuest = !syncState.isSignedIn;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: safePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isGuest
                      ? Colors.white.withValues(alpha: 0.1)
                      : PinTokens.accentEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGuest
                        ? Colors.white.withValues(alpha: 0.2)
                        : PinTokens.accentEmerald.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  isGuest ? 'ACCOUNT (GUEST)' : 'ACCOUNT',
                  style: TextStyle(
                    color: isGuest ? Colors.white70 : PinTokens.accentEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (isGuest) ...[
            // Guest Sign-In Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141916),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PinTokens.accentSage.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_queue_rounded,
                    size: 26,
                    color: PinTokens.accentSage,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cloud Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to sync your pins across phone, web & watch.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (syncState.errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      syncState.errorMessage!,
                      style: const TextStyle(
                        color: PinTokens.accentRose,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PinTokens.accentSage,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.account_circle_outlined, size: 16),
                      label: const Text(
                        'GOOGLE SIGN-IN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      onPressed: () => _showWatchGoogleSignIn(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.mail_outline_rounded, size: 15),
                      label: const Text(
                        'EMAIL SIGN-IN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _showWatchEmailSignIn(context),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Authenticated User Profile Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141916),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PinTokens.accentEmerald.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: PinTokens.accentEmerald.withValues(alpha: 0.2),
                        backgroundImage: syncState.user?.photoURL != null
                            ? NetworkImage(syncState.user!.photoURL!)
                            : null,
                        child: syncState.user?.photoURL == null
                            ? const Icon(Icons.person, size: 14, color: PinTokens.accentEmerald)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syncState.user?.displayName ?? 'Pin User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              syncState.user?.email ?? 'Logged In',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sync status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A211D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (syncState.status == SyncStatus.syncing)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  PinTokens.accentEmerald),
                            ),
                          )
                        else
                          Icon(
                            syncState.status == SyncStatus.synced
                                ? Icons.cloud_done_rounded
                                : syncState.status == SyncStatus.error
                                    ? Icons.cloud_off_rounded
                                    : Icons.cloud_queue_rounded,
                            size: 13,
                            color: syncState.status == SyncStatus.synced
                                ? PinTokens.accentEmerald
                                : syncState.status == SyncStatus.error
                                    ? PinTokens.accentRose
                                    : Colors.white54,
                          ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            syncState.status == SyncStatus.syncing
                                ? 'Syncing...'
                                : syncState.status == SyncStatus.synced
                                    ? 'Synced (${syncState.syncedTaskCount} pins)'
                                    : syncState.status == SyncStatus.error
                                        ? 'Sync error'
                                        : 'Offline mode',
                            style: TextStyle(
                              color: syncState.status == SyncStatus.synced
                                  ? PinTokens.accentEmerald
                                  : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PinTokens.accentSage,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 15),
                      label: const Text(
                        'SYNC NOW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        ref.read(syncControllerProvider.notifier).syncNow();
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 14),
                      label: const Text(
                        'SIGN OUT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        ref.read(syncControllerProvider.notifier).signOut();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Swipe left for Today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showWatchGoogleSignIn(BuildContext context) async {
    final controller = ref.read(syncControllerProvider.notifier);
    final emailCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141916),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: PinTokens.accentSage, width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        actionsPadding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle_outlined,
                color: PinTokens.accentSage, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Google Sign-In',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Google email to sync:',
              style: TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'user@gmail.com',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF1E211F),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: PinTokens.accentSage),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL',
                      style: TextStyle(fontSize: 10, color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PinTokens.accentSage,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final email = emailCtrl.text.trim().toLowerCase();
                    final success = await controller.signInWithGoogle(
                      email: email.isNotEmpty ? email : null,
                    );
                    if (!success && context.mounted) {
                      final errorMsg =
                          ref.read(syncControllerProvider).errorMessage ?? '';
                      if (errorMsg.contains('password') ||
                          errorMsg.contains('EMAIL_EXISTS')) {
                        _showWatchEmailSignIn(
                          context,
                          prefillEmail: email,
                          hintMessage: 'Password required for this email',
                        );
                      }
                    }
                  },
                  child: const Text('SIGN IN',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showWatchEmailSignIn(
    BuildContext context, {
    String? prefillEmail,
    String? hintMessage,
  }) async {
    final controller = ref.read(syncControllerProvider.notifier);
    final emailCtrl = TextEditingController(text: prefillEmail ?? '');
    final passCtrl = TextEditingController();
    final hasPrefill = prefillEmail != null && prefillEmail.trim().isNotEmpty;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141916),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: PinTokens.accentSage, width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        actionsPadding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline_rounded,
                color: PinTokens.accentSage, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Email Sign-In',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hintMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PinTokens.accentSage.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hintMessage,
                  style: const TextStyle(
                    color: PinTokens.accentSage,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: !hasPrefill,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF1E211F),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: PinTokens.accentSage),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: passCtrl,
              obscureText: true,
              autofocus: hasPrefill,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF1E211F),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: PinTokens.accentSage),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL',
                      style: TextStyle(fontSize: 10, color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PinTokens.accentSage,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await controller.signInWithEmail(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                    );
                  },
                  child: const Text('SIGN IN',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161817),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 24, color: PinTokens.accentSage),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Standalone watch focus mode view with oversized touch controls and circular edge padding.
class WearableFocusView extends ConsumerStatefulWidget {
  final PinTask task;
  final VoidCallback onExit;

  const WearableFocusView({
    super.key,
    required this.task,
    required this.onExit,
  });

  @override
  ConsumerState<WearableFocusView> createState() => _WearableFocusViewState();
}

class _WearableFocusViewState extends ConsumerState<WearableFocusView> {
  late PinTask _currentTask;
  Timer? _timer;
  bool _isRunning = false;
  int _sessionSeconds = 0;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _sessionSeconds++);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  Future<void> _persistLoggedTime() async {
    if (_sessionSeconds > 0) {
      final notifier = ref.read(taskStateProvider.notifier);
      await notifier.logTimeSpent(_currentTask.id, _sessionSeconds);
      _sessionSeconds = 0;
    }
  }

  Future<void> _exitFocus() async {
    if (_isExiting) return;
    _isExiting = true;
    _pauseTimer();
    await _persistLoggedTime();
    ref.read(activeFocusTaskProvider.notifier).state = null;
    widget.onExit();
  }

  Future<void> _completeTask() async {
    _pauseTimer();
    await _persistLoggedTime();
    final notifier = ref.read(taskStateProvider.notifier);
    await notifier.moveToDone(_currentTask.id);
    await _exitFocus();
  }

  void _toggleStep(int index, bool isCompleted) {
    final step = _currentTask.subtasks[index];
    final updatedStep = step.copyWith(isCompleted: isCompleted);
    final updatedList = List<AtomicStep>.from(_currentTask.subtasks)
      ..[index] = updatedStep;
    final updatedTask = _currentTask.copyWith(subtasks: updatedList);

    setState(() => _currentTask = updatedTask);
    ref.read(taskStateProvider.notifier).updateTask(updatedTask);
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalElapsedSeconds = _currentTask.trackedSeconds + _sessionSeconds;
    final safePadding = WearableUtils.getSafeCircularPadding(context, extra: 4);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitFocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: safePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Exit Icon & Task Title
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                      onPressed: _exitFocus,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTask.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_currentTask.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _currentTask.description.trim(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 9.5,
                                height: 1.18,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Center Timer Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141916),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isRunning
                            ? PinTokens.accentEmerald.withValues(alpha: 0.6)
                            : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _formatTimer(totalElapsedSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Controls Row (Pause/Play + Complete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _toggleTimer,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isRunning
                              ? Colors.amber.withValues(alpha: 0.2)
                              : PinTokens.accentEmerald.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRunning ? Colors.amber : PinTokens.accentEmerald,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 22,
                          color: _isRunning ? Colors.amber : PinTokens.accentEmerald,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _completeTask,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PinTokens.accentEmerald.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PinTokens.accentEmerald,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 22,
                          color: PinTokens.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Steps / Subtasks list if any
                if (_currentTask.subtasks.isNotEmpty) ...[
                  Text(
                    'STEPS (${_currentTask.completedSubtasksCount}/${_currentTask.totalSubtasksCount})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (int i = 0; i < _currentTask.subtasks.length; i++) ...[
                    _buildStepRow(i, _currentTask.subtasks[i]),
                    const SizedBox(height: 4),
                  ],
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(int index, AtomicStep step) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _toggleStep(index, !step.isCompleted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF191B1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              step.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: step.isCompleted ? PinTokens.accentEmerald : Colors.white38,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  color: step.isCompleted ? Colors.white38 : Colors.white,
                  fontSize: 11,
                  decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
