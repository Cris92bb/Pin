import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'focus_mode_body.dart';
import 'focus_mode_celebration_view.dart';

/// Immersive, distraction-free execution engine for a single task.
class FocusModeView extends ConsumerStatefulWidget {
  /// The task to execute.
  final PinTask task;

  /// Callback to exit focus mode.
  final VoidCallback onExit;

  /// Optional callback to edit task.
  final Future<void> Function(PinTask task)? onEditTask;

  /// Optional callback to reanalyze task with AI.
  final Future<bool?> Function(PinTask task)? onReanalyzeWithAi;

  /// Creates a [FocusModeView].
  const FocusModeView({
    super.key,
    required this.task,
    required this.onExit,
    this.onEditTask,
    this.onReanalyzeWithAi,
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
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _stepController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _startTimer();
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
    if (widget.onEditTask != null) {
      await widget.onEditTask!(_currentTask);
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
    if (widget.onReanalyzeWithAi != null) {
      final success = await widget.onReanalyzeWithAi!(_currentTask);
      if (!mounted) return;
      if (success == true) {
        final state = ref.read(taskStateProvider);
        final match = state.tasks.where((t) => t.id == _currentTask.id);
        if (match.isNotEmpty) {
          setState(() => _currentTask = match.first);
        }
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

    final totalElapsedSeconds = _currentTask.trackedSeconds + _sessionSeconds;
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
              isDark ? PinTokens.darkSheetBg : PinTokens.lightPhoneFrameBg,
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: PinTokens.animNormal,
              child: _isCompletedState
                  ? FocusModeCelebrationView(isDark: isDark)
                  : FocusModeBody(
                      task: _currentTask,
                      isDark: isDark,
                      scrollController: _scrollController,
                      stepController: _stepController,
                      totalElapsedSeconds: totalElapsedSeconds,
                      sessionSeconds: _sessionSeconds,
                      isRunning: _isRunning,
                      isScrolledPastTimer: _isScrolledPastTimer,
                      onExit: _exitFocus,
                      onReanalyzeWithAi: _reanalyzeTaskWithAi,
                      onEditTask: _editTask,
                      onCompleteTask: _completeTask,
                      onToggleTimer: _toggleTimer,
                      onResetTimer: () {
                        setState(() => _sessionSeconds = 0);
                      },
                      onToggleStep: _toggleStep,
                      onDeleteStep: _deleteStep,
                      onAddNewStep: _addNewStep,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
