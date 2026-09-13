import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/atomic_step/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../wearable_utils.dart';

/// Optimized, glanceable smartwatch interface for Pin.
/// Designed specifically for circular and square Wear OS screens.
class WearableHomePage extends ConsumerStatefulWidget {
  const WearableHomePage({super.key});

  @override
  ConsumerState<WearableHomePage> createState() => _WearableHomePageState();
}

class _WearableHomePageState extends ConsumerState<WearableHomePage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFocus = ref.watch(activeFocusTaskProvider);
    final taskState = ref.watch(taskStateProvider);

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildTodayPage(context, taskState, safePadding),
                _buildBacklogPage(context, taskState, safePadding),
                _buildDonePage(context, taskState, safePadding),
              ],
            ),
            // Page indicator dots at top
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
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
            _buildEmptyCard('No tasks for today', 'Swipe right for Backlog')
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141916),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PinTokens.accentSage.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 8),
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
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text(
                'START FOCUS',
                style: TextStyle(
                  fontSize: 11,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E211F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
            _buildEmptyCard('Backlog is empty', 'Add pins from companion app')
          else ...[
            for (final task in backlogTasks) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1D1C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
            _buildEmptyCard('No finished pins', 'Completed pins appear here')
          else ...[
            for (final task in doneTasks.take(10)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: PinTokens.accentEmerald),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
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
                      child: Text(
                        _currentTask.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
