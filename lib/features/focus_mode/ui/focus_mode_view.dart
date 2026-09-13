import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/atomic_step/model/atomic_step.dart';
import '../../../entities/atomic_step/ui/atomic_step_tile.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../shared/ui/pill_chip.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../../ai/ui/ai_task_breakdown_modal.dart';
import '../../task_crud/ui/task_crud_modal.dart';

/// Immersive, distraction-free execution engine for a single task.
class FocusModeView extends ConsumerStatefulWidget {
  final PinTask task;
  final VoidCallback onExit;

  const FocusModeView({
    super.key,
    required this.task,
    required this.onExit,
  });

  @override
  ConsumerState<FocusModeView> createState() => _FocusModeViewState();
}

class _FocusModeViewState extends ConsumerState<FocusModeView> {
  late PinTask _currentTask;
  late final TextEditingController _stepController;
  final FocusNode _keyboardFocusNode = FocusNode();

  Timer? _timer;
  bool _isRunning = false;
  int _sessionSeconds = 0;
  bool _isCompletedState = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _stepController = TextEditingController();
    _startTimer(); // Auto-start timer upon entering Focus Mode for instant immersion
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    await _persistLoggedTime();
    ref.read(activeFocusTaskProvider.notifier).state = null;
    widget.onExit();
  }

  Future<void> _completeTask() async {
    _pauseTimer();
    await _persistLoggedTime();

    setState(() => _isCompletedState = true);

    final notifier = ref.read(taskStateProvider.notifier);
    await notifier.moveToDone(_currentTask.id);

    // Give visual celebration feedback before exiting
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      await _exitFocus();
    }
  }

  Future<void> _editTask() async {
    await _persistLoggedTime();
    if (!mounted) return;
    await TaskCrudModal.show(context, task: _currentTask);
    if (!mounted) return;
    final state = ref.read(taskStateProvider);
    final match = state.tasks.where((t) => t.id == _currentTask.id);
    if (match.isNotEmpty) {
      setState(() => _currentTask = match.first);
    }
  }

  Future<void> _reanalyzeTaskWithAi() async {
    await _persistLoggedTime();
    if (!mounted) return;
    final success =
        await AiTaskBreakdownModal.show(context, task: _currentTask);
    if (!mounted) return;
    if (success == true) {
      final state = ref.read(taskStateProvider);
      final match = state.tasks.where((t) => t.id == _currentTask.id);
      if (match.isNotEmpty) {
        setState(() => _currentTask = match.first);
      }
    }
  }

  void _addNewStep() {
    final title = _stepController.text.trim();
    if (title.isEmpty) return;

    final newStep = AtomicStep(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      isCompleted: false,
      estimatedMinutes: 15,
    );

    final updated = List<AtomicStep>.from(_currentTask.subtasks)..add(newStep);
    final updatedTask = _currentTask.copyWith(subtasks: updated);

    setState(() {
      _currentTask = updatedTask;
      _stepController.clear();
    });

    ref.read(taskStateProvider.notifier).updateTask(updatedTask);
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

  @override
  Widget build(BuildContext context) {
    // Total elapsed time including previous sessions
    final totalElapsedSeconds =
        _currentTask.trackedSeconds + _sessionSeconds;
    final totalSteps = _currentTask.totalSubtasksCount;
    final completedSteps = _currentTask.completedSubtasksCount;
    final progress = _currentTask.subtaskProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _exitFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.space &&
              !_stepController.text.isNotEmpty &&
              !FocusScope.of(context).hasPrimaryFocus) {
            _toggleTimer();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightPhoneFrameBg,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: PinTokens.animNormal,
            child: _isCompletedState
                ? _buildCelebrationView(isDark)
                : _buildImmersiveView(
                    totalElapsedSeconds,
                    totalSteps,
                    completedSteps,
                    progress,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PinTokens.accentEmerald.withValues(alpha: 0.15),
              border: Border.all(color: PinTokens.accentEmerald, width: 2),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 56,
              color: PinTokens.accentEmerald,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Task Completed!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? PinTokens.darkTextPrimary
                  : PinTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great execution momentum. Returning to board...',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? PinTokens.darkTextSecondary
                  : PinTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersiveView(
    int totalElapsedSeconds,
    int totalSteps,
    int completedSteps,
    double progress,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        final isVeryNarrow = constraints.maxWidth < 360;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final textPrimary =
            isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
        final textSecondary =
            isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
        final textMuted =
            isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted;
        final borderSubtle =
            isDark ? PinTokens.darkBorderSubtle : PinTokens.lightBorderSubtle;
        final borderDefault =
            isDark ? PinTokens.borderDefault : PinTokens.lightBorderSubtle;

        final timerCardBg =
            isDark ? PinTokens.surfaceColumn : const Color(0xFFF8FAFC);
        final checklistCardBg = isDark
            ? PinTokens.surfaceColumn.withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC);
        final inputBg = isDark ? PinTokens.surfaceCard : Colors.white;

        return Column(
          children: [
            // Top Minimalist Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? PinTokens.space12 : PinTokens.space24,
                vertical: PinTokens.space12,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderSubtle)),
              ),
              child: Row(
                children: [
                  PinButton(
                    icon: Icons.arrow_back_rounded,
                    text: isNarrow ? (isVeryNarrow ? null : 'Back') : 'Kanban Board',
                    isCompact: true,
                    tooltip: 'Return to Board (Esc)',
                    onPressed: _exitFocus,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PinTokens.accentViolet.withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: PinTokens.radiusFull,
                      border: Border.all(
                        color: PinTokens.accentViolet.withValues(alpha: isDark ? 0.6 : 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PinTokens.accentViolet,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isNarrow ? 'FOCUS' : 'SINGLE-TASK IMMERSION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? PinTokens.accentViolet
                                : const Color(0xFF6D28D9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!isNarrow) ...[
                    PinButton(
                      icon: Icons.auto_awesome_rounded,
                      text: 'AI Breakdown',
                      isCompact: true,
                      tooltip: 'AI Breakdown & Re-analyze',
                      onPressed: _reanalyzeTaskWithAi,
                    ),
                    const SizedBox(width: 8),
                    PinButton(
                      icon: Icons.edit_outlined,
                      text: 'Edit',
                      isCompact: true,
                      tooltip: 'Edit Pin',
                      onPressed: _editTask,
                    ),
                    const SizedBox(width: 8),
                  ],
                  PinButton.primary(
                    icon: Icons.check_circle_outline_rounded,
                    text: isNarrow ? (isVeryNarrow ? null : 'Done') : 'Done & Exit',
                    isCompact: true,
                    onPressed: _completeTask,
                  ),
                ],
              ),
            ),

            // Core Task & Timer Canvas
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? PinTokens.space16 : PinTokens.space24,
                  vertical: PinTokens.space20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Meta Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PillChip.energy(
                              tag: _currentTask.energyTag,
                              isCompact: true,
                            ),
                            const SizedBox(width: 8),
                            PillChip.duration(
                              durationText: DateHelpers.formatMinutes(
                                  _currentTask.estimatedMinutes),
                              isCompact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Task Title
                        Text(
                          _currentTask.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                            height: 1.25,
                          ),
                        ),
                        if (_currentTask.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _currentTask.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Big Live Stopwatch Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: timerCardBg,
                            borderRadius: PinTokens.radiusLg,
                            border: Border.all(
                              color: _isRunning
                                  ? PinTokens.accentViolet.withValues(alpha: isDark ? 0.5 : 0.7)
                                  : borderDefault,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateHelpers.formatSeconds(totalElapsedSeconds),
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: textPrimary,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRunning
                                    ? 'Session Live • +${DateHelpers.formatSeconds(_sessionSeconds)}'
                                    : 'Session Paused',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isRunning
                                      ? (isDark
                                          ? PinTokens.accentViolet
                                          : const Color(0xFF6D28D9))
                                      : textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  PinButton(
                                    icon: _isRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    text: _isRunning ? 'Pause' : 'Resume',
                                    variant: _isRunning
                                        ? PinButtonVariant.secondary
                                        : PinButtonVariant.primary,
                                    width: 120,
                                    onPressed: _toggleTimer,
                                  ),
                                  PinButton(
                                    icon: Icons.refresh_rounded,
                                    text: 'Reset',
                                    variant: PinButtonVariant.secondary,
                                    width: 120,
                                    onPressed: () {
                                      setState(() => _sessionSeconds = 0);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Checklist Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(PinTokens.space16),
                          decoration: BoxDecoration(
                            color: checklistCardBg,
                            borderRadius: PinTokens.radiusMd,
                            border: Border.all(
                              color: isDark
                                  ? PinTokens.borderDefault.withValues(alpha: 0.7)
                                  : borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Atomic Subtasks',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
                                  ),
                                  if (totalSteps > 0)
                                    Text(
                                      '$completedSteps / $totalSteps completed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: completedSteps == totalSteps
                                            ? PinTokens.accentEmerald
                                            : textMuted,
                                      ),
                                    ),
                                ],
                              ),
                              if (totalSteps > 0) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: PinTokens.radiusFull,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: isDark
                                        ? PinTokens.canvasBg
                                        : const Color(0xFFE5E7EB),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      PinTokens.accentEmerald,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Steps list
                              if (_currentTask.subtasks.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Text(
                                      'No subtasks yet. Break this task into bite-sized steps below.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _currentTask.subtasks.length,
                                    itemBuilder: (context, index) {
                                      final step = _currentTask.subtasks[index];
                                      return AtomicStepTile(
                                        step: step,
                                        isEditable: false,
                                        onToggle: (checked) =>
                                            _toggleStep(index, checked),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),

                              // Quick add step
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _stepController,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Add micro-step (<= 15m)...',
                                        hintStyle: TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                        ),
                                        filled: true,
                                        fillColor: inputBg,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: PinTokens.radiusMd,
                                          borderSide: BorderSide(
                                            color: borderDefault,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: PinTokens.radiusMd,
                                          borderSide: BorderSide(
                                            color: borderDefault,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: PinTokens.radiusMd,
                                          borderSide: BorderSide(
                                            color: PinTokens.accentViolet,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      onSubmitted: (_) => _addNewStep(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PinButton(
                                    icon: Icons.add_rounded,
                                    text: 'Add',
                                    isCompact: true,
                                    onPressed: _addNewStep,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
