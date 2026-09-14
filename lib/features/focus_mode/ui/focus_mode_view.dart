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
import '../../../shared/ui/pin_breakpoints.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../../ai/ui/ai_task_breakdown_modal.dart';
import '../../task_crud/state/task_editor_state.dart';
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
  late final ScrollController _scrollController;
  final FocusNode _keyboardFocusNode = FocusNode();

  Timer? _timer;
  bool _isRunning = false;
  int _sessionSeconds = 0;
  bool _isCompletedState = false;
  bool _isScrolledPastTimer = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _stepController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _startTimer(); // Auto-start timer upon entering Focus Mode for instant immersion
  }

  @override
  void didUpdateWidget(covariant FocusModeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _pauseTimer();
      _persistLoggedTime();
      setState(() {
        _currentTask = widget.task;
        _sessionSeconds = 0;
        _isCompletedState = false;
        _stepController.clear();
      });
      _startTimer();
    } else if (oldWidget.task != widget.task) {
      setState(() {
        _currentTask = widget.task;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isPast = _scrollController.offset > 170;
    if (isPast != _isScrolledPastTimer) {
      setState(() => _isScrolledPastTimer = isPast);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

  bool _isExiting = false;

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
    if (PinBreakpoints.isWide(context)) {
      ref.read(activeTaskEditorProvider.notifier).state =
          TaskEditorArgs(task: _currentTask);
    } else {
      await TaskCrudModal.show(context, task: _currentTask);
      if (!mounted) return;
      final state = ref.read(taskStateProvider);
      final match = state.tasks.where((t) => t.id == _currentTask.id);
      if (match.isNotEmpty) {
        setState(() => _currentTask = match.first);
      }
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

  void _deleteStep(int index) {
    final updatedList = List<AtomicStep>.from(_currentTask.subtasks)
      ..removeAt(index);
    final updatedTask = _currentTask.copyWith(subtasks: updatedList);

    setState(() => _currentTask = updatedTask);
    ref.read(taskStateProvider.notifier).updateTask(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskStateProvider);
    final match = taskState.tasks.where((t) => t.id == _currentTask.id);
    if (match.isNotEmpty && match.first != _currentTask) {
      _currentTask = match.first;
    }

    // Total elapsed time including previous sessions
    final totalElapsedSeconds =
        _currentTask.trackedSeconds + _sessionSeconds;
    final totalSteps = _currentTask.totalSubtasksCount;
    final completedSteps = _currentTask.completedSubtasksCount;
    final progress = _currentTask.subtaskProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitFocus();
      },
      child: Focus(
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
              isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCanvasBg,
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

  Widget _buildStickyTimerBanner(
    bool isDark,
    int totalElapsedSeconds,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color borderSubtle,
  ) {
    final bannerBg = isDark ? PinTokens.surfaceColumn : PinTokens.lightSheetBg;

    return Container(
      key: const ValueKey('sticky_timer_banner'),
      padding: const EdgeInsets.symmetric(
        horizontal: PinTokens.space16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(color: borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRunning
                  ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                  : textMuted,
            ),
          ),
          const SizedBox(width: 8),

          // Compact Timer Digits
          Text(
            DateHelpers.formatSeconds(totalElapsedSeconds),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),

          // Status text
          Text(
            _isRunning ? 'Live' : 'Paused',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isRunning
                  ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                  : textMuted,
            ),
          ),

          const Spacer(),

          // Compact action buttons
          PinButton(
            icon: _isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            text: _isRunning ? 'Pause' : 'Resume',
            variant: _isRunning
                ? PinButtonVariant.secondary
                : PinButtonVariant.primary,
            isCompact: true,
            onPressed: _toggleTimer,
          ),
          const SizedBox(width: 8),
          PinButton(
            icon: Icons.refresh_rounded,
            text: 'Reset',
            variant: PinButtonVariant.secondary,
            isCompact: true,
            onPressed: () {
              setState(() => _sessionSeconds = 0);
            },
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
        final isNarrow = constraints.maxWidth < 680;
        final isVeryNarrow = constraints.maxWidth < 360;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final textPrimary =
            isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
        final textSecondary =
            isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
        final textMuted =
            isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted;
        final borderSubtle =
            isDark ? PinTokens.darkBorderSubtle : PinTokens.lightBorder;
        final borderDefault =
            isDark ? PinTokens.borderDefault : PinTokens.lightBorder;

        // Subtasks background matches the sliding sheet surface in light mode
        final subtasksBg = isDark
            ? const Color(0xFF161A26)
            : PinTokens.lightSheetBg;

        final inputBg = isDark ? PinTokens.surfaceCard : PinTokens.lightCardBg;

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
                    text: isNarrow ? (isVeryNarrow ? null : 'Back') : 'Back',
                    isCompact: true,
                    tooltip: 'Return to Board (Esc)',
                    onPressed: _exitFocus,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? PinTokens.accentEmerald.withValues(alpha: 0.15)
                          : PinTokens.lightTagBg,
                      borderRadius: PinTokens.radiusFull,
                      border: Border.all(
                        color: isDark
                            ? PinTokens.accentEmerald.withValues(alpha: 0.5)
                            : PinTokens.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? PinTokens.accentEmerald
                                : PinTokens.lightFabBg,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isNarrow ? 'FOCUS' : 'SINGLE-TASK IMMERSION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? PinTokens.accentEmerald
                                : PinTokens.lightTextPrimary,
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
                  ],
                  if (!isVeryNarrow) ...[
                    PinButton(
                      icon: Icons.edit_outlined,
                      text: isNarrow ? null : 'Edit',
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

            // Top Sticky Minimized Timer Banner (appears when scrolling past the big timer)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: _isScrolledPastTimer
                  ? _buildStickyTimerBanner(
                      isDark,
                      totalElapsedSeconds,
                      textPrimary,
                      textSecondary,
                      textMuted,
                      borderSubtle,
                    )
                  : const SizedBox.shrink(),
            ),

            // Unified Scrollable Canvas
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Timer & Task Hero Section (No card / No outline)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? PinTokens.space16 : PinTokens.space24,
                        PinTokens.space16,
                        isNarrow ? PinTokens.space16 : PinTokens.space24,
                        PinTokens.space16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
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
                            const SizedBox(height: 24),

                            // Big Stopwatch Display (Clean: No outline card effect)
                            Column(
                              children: [
                                Text(
                                  DateHelpers.formatSeconds(totalElapsedSeconds),
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                    color: textPrimary,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isRunning
                                      ? 'Session Live • +${DateHelpers.formatSeconds(_sessionSeconds)}'
                                      : 'Session Paused',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _isRunning
                                        ? (isDark
                                            ? PinTokens.accentEmerald
                                            : PinTokens.lightFabBg)
                                        : textMuted,
                                  ),
                                ),
                                const SizedBox(height: 20),
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
                          ],
                        ),
                      ),
                    ),

                    // Full-Screen Subtasks Section (Slightly different background, no card outline)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 100 > 240
                            ? constraints.maxHeight - 100
                            : 240,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              isNarrow ? PinTokens.space16 : PinTokens.space24,
                          vertical: PinTokens.space20,
                        ),
                        decoration: BoxDecoration(
                          color: subtasksBg,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
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
                                        fontSize: 14,
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
                                              ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                                              : textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                                if (totalSteps > 0) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: PinTokens.radiusFull,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      backgroundColor: isDark
                                          ? PinTokens.canvasBg
                                          : PinTokens.lightBorder,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // Subtasks list (full view, no 180px truncation)
                                if (_currentTask.subtasks.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32.0),
                                    child: Center(
                                      child: Text(
                                        'No subtasks yet. Break this task into bite-sized steps below.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _currentTask.subtasks.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 4),
                                    itemBuilder: (context, index) {
                                      final step =
                                          _currentTask.subtasks[index];
                                      return AtomicStepTile(
                                        step: step,
                                        isEditable: true,
                                        onToggle: (checked) =>
                                            _toggleStep(index, checked),
                                        onDelete: () => _deleteStep(index),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 16),

                                // Quick add step
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _stepController,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Add micro-step (<= 15m)...',
                                          hintStyle: TextStyle(
                                            color: textMuted,
                                            fontSize: 13,
                                          ),
                                          filled: true,
                                          fillColor: inputBg,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
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
                                          focusedBorder:
                                              OutlineInputBorder(
                                            borderRadius: PinTokens.radiusMd,
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? PinTokens.accentEmerald
                                                  : PinTokens.lightFabBg,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
