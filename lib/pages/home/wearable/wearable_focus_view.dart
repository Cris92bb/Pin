import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/wearable_utils.dart';
import 'wearable_focus_controls.dart';

/// Standalone watch focus mode view with oversized touch controls and circular edge padding.
class WearableFocusView extends ConsumerStatefulWidget {
  /// The task being focused on.
  final PinTask task;

  /// Callback executed when exiting focus mode.
  final VoidCallback onExit;

  /// Creates a [WearableFocusView] for [task].
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
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white70, size: 20),
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
                WearableFocusTimerCard(
                  formattedTime: _formatTimer(totalElapsedSeconds),
                  isRunning: _isRunning,
                ),
                const SizedBox(height: 10),

                // Controls Row (Pause/Play + Complete)
                WearableFocusActionButtons(
                  isRunning: _isRunning,
                  onToggleTimer: _toggleTimer,
                  onCompleteTask: _completeTask,
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
                    WearableFocusStepTile(
                      step: _currentTask.subtasks[i],
                      onToggle: (completed) => _toggleStep(i, completed),
                    ),
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
}
