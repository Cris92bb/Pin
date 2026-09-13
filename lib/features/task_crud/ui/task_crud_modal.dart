import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/atomic_step/model/atomic_step.dart';
import '../../../entities/atomic_step/ui/atomic_step_tile.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../shared/ui/pill_chip.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../../ai/services/ai_config_service.dart';
import '../../ai/services/gemini_service.dart';
import '../../ai/ui/ai_settings_modal.dart';

/// Modal dialog for creating or editing Pins with tags, estimation chips, and energy states.
class TaskCrudModal extends ConsumerStatefulWidget {
  final PinTask? initialTask;
  final TaskStatus? defaultStatus;
  final bool autoTriggerAi;

  const TaskCrudModal({
    super.key,
    this.initialTask,
    this.defaultStatus,
    this.autoTriggerAi = false,
  });

  static Future<void> show(
    BuildContext context, {
    PinTask? task,
    TaskStatus? defaultStatus,
    bool autoTriggerAi = false,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => TaskCrudModal(
        initialTask: task,
        defaultStatus: defaultStatus,
        autoTriggerAi: autoTriggerAi,
      ),
    );
  }

  @override
  ConsumerState<TaskCrudModal> createState() => _TaskCrudModalState();
}

class _TaskCrudModalState extends ConsumerState<TaskCrudModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _subtaskController;
  late final TextEditingController _tagController;

  late TaskStatus _selectedStatus;
  late String _selectedEnergyTag;
  late int _selectedEstimateMinutes;
  late List<String> _tags;
  late List<AtomicStep> _subtasks;
  String? _inlineError;
  bool _isGeneratingWithAi = false;

  static const List<int> _estimationOptions = [5, 15, 30, 45, 60, 120];
  static const List<String> _energyTags = [
    'low-friction',
    'medium-flow',
    'deep-focus',
    'creative',
    'administrative',
  ];
  static const List<String> _quickTags = [
    '#dev',
    '#ui',
    '#admin',
    '#quick-win',
    '#design',
    '#docs',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _subtaskController = TextEditingController();
    _tagController = TextEditingController();

    _selectedStatus =
        task?.status ?? widget.defaultStatus ?? TaskStatus.today;
    _selectedEnergyTag = task?.energyTag ?? 'low-friction';
    _selectedEstimateMinutes = task?.estimatedMinutes ?? 15;
    _tags = task?.tags != null ? List.from(task!.tags) : ['#dev'];
    _subtasks = task?.subtasks != null ? List.from(task!.subtasks) : [];

    if (widget.autoTriggerAi) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _generateTaskWithAi();
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(
        AtomicStep(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: text,
          isCompleted: false,
          estimatedMinutes: 15,
        ),
      );
      _subtaskController.clear();
    });
  }

  void _addTag(String tag) {
    final clean = tag.startsWith('#') ? tag : '#$tag';
    if (!_tags.contains(clean)) {
      setState(() => _tags.add(clean));
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _generateTaskWithAi() async {
    final aiConfig = ref.read(aiConfigProvider);
    if (!aiConfig.hasKey) {
      final configured = await AiSettingsModal.show(context);
      if (configured != true || !mounted) return;
      if (!ref.read(aiConfigProvider).hasKey) return;
    }

    final prompt = _titleController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _inlineError = 'Please enter a task title or idea first so Gemini can analyze it.';
      });
      return;
    }

    setState(() {
      _isGeneratingWithAi = true;
      _inlineError = null;
    });

    try {
      final service = GeminiService();
      final currentDesc = _descController.text.trim();
      final breakdown = await service.suggestTaskBreakdown(
        apiKey: ref.read(aiConfigProvider).apiKey,
        prompt: prompt,
        currentDescription: currentDesc.isNotEmpty ? currentDesc : null,
        model: ref.read(aiConfigProvider).selectedModel,
      );

      if (mounted) {
        setState(() {
          _titleController.text = breakdown.title;
          if (breakdown.description.isNotEmpty) {
            _descController.text = breakdown.description;
          }
          _selectedEnergyTag = breakdown.energyTag;
          _selectedEstimateMinutes = breakdown.estimatedMinutes;
          _tags = List.from(breakdown.tags);
          _subtasks = List.from(breakdown.atomicSteps);
          _inlineError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Gemini decomposed this into ${breakdown.atomicSteps.length} atomic steps and filled all properties!',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inlineError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingWithAi = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _inlineError = 'Pin title cannot be empty.');
      return;
    }

    final notifier = ref.read(taskStateProvider.notifier);
    final now = DateTime.now();

    if (widget.initialTask == null) {
      final newTask = PinTask(
        id: 'pin_${now.microsecondsSinceEpoch}',
        title: title,
        description: _descController.text.trim(),
        status: _selectedStatus,
        isPinned: _selectedStatus == TaskStatus.today,
        energyTag: _selectedEnergyTag,
        estimatedMinutes: _selectedEstimateMinutes,
        tags: _tags,
        trackedSeconds: 0,
        subtasks: _subtasks,
        createdAt: now,
        updatedAt: now,
      );

      final success = await notifier.createTask(newTask);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          final state = ref.read(taskStateProvider);
          setState(() {
            _inlineError = state.alertMessage ?? 'WIP limit reached!';
          });
        }
      }
    } else {
      final updated = widget.initialTask!.copyWith(
        title: title,
        description: _descController.text.trim(),
        status: _selectedStatus,
        isPinned: _selectedStatus == TaskStatus.today,
        energyTag: _selectedEnergyTag,
        estimatedMinutes: _selectedEstimateMinutes,
        tags: _tags,
        subtasks: _subtasks,
        updatedAt: now,
      );

      final success = await notifier.updateTask(updated);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          final state = ref.read(taskStateProvider);
          setState(() {
            _inlineError = state.alertMessage ?? 'WIP limit reached!';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    final taskState = ref.watch(taskStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final modalBg = isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final inputBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg;

    return Dialog(
      backgroundColor: modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusDeck,
        side: BorderSide(color: borderColor, width: isDark ? 1.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Pin' : 'Capture New Pin',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Gemini AI Settings',
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                        splashRadius: 18,
                        onPressed: () => AiSettingsModal.show(context),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextTertiary,
                          size: 20,
                        ),
                        splashRadius: 18,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Inline Alert
              if (_inlineError != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: PinTokens.accentAmber.withValues(alpha: 0.12),
                    borderRadius: PinTokens.radiusMd,
                    border: Border.all(
                      color: PinTokens.accentAmber.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: PinTokens.accentAmber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PinTokens.accentAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title input
                      TextField(
                        controller: _titleController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What needs execution?',
                          hintStyle: TextStyle(
                            color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(color: borderColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(color: borderColor, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(
                              color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg,
                              width: 1.2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 8),

                      // Gemini AI Auto-Fill & Breakdown Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: PinTokens.radiusMd,
                          onTap: _isGeneratingWithAi ? null : _generateTaskWithAi,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              borderRadius: PinTokens.radiusMd,
                              color: isDark
                                  ? const Color(0xFF1B2520)
                                  : PinTokens.lightTagBg,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2E4536)
                                    : PinTokens.lightBorder,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isGeneratingWithAi) ...[
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Decomposing task with Gemini...',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 15,
                                    color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.initialTask != null
                                          ? 'Re-analyze & break down with Gemini'
                                          : 'Break down & auto-fill with Gemini',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description input
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Optional notes, blockers, or context...',
                          hintStyle: TextStyle(
                            color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(color: borderColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(color: borderColor, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(
                              color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Target Column Selection
                      Text(
                        'Target Deck',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildColumnOption(
                              label: 'To do',
                              status: TaskStatus.today,
                              badge: '${taskState.todayCount}/${taskState.wipLimit} focus',
                              isFull: taskState.isTodayWipFull &&
                                  widget.initialTask?.status != TaskStatus.today,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            _buildColumnOption(
                              label: 'Backlog',
                              status: TaskStatus.backlog,
                              badge: '${taskState.backlogTasks.length} queued',
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                            ),
                            if (isEditing) ...[
                              const SizedBox(width: 8),
                              _buildColumnOption(
                                label: 'Done',
                                status: TaskStatus.done,
                                badge: '${taskState.doneTasks.length} done',
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hashtag Tags
                      Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final tag in _tags)
                            Chip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary,
                                ),
                              ),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isDark ? PinTokens.darkBorder : PinTokens.lightBorder,
                                  width: 1.0,
                                ),
                              ),
                              backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightSheetBg,
                              deleteIcon: Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                              ),
                              onDeleted: () => _removeTag(tag),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          for (final qTag in _quickTags)
                            if (!_tags.contains(qTag))
                              ActionChip(
                                label: Text(
                                  qTag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
                                  ),
                                ),
                                shape: const StadiumBorder(
                                  side: BorderSide(
                                    color: PinTokens.lightBorder,
                                    width: 1.0,
                                  ),
                                ),
                                backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightTagBg,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                onPressed: () => _addTag(qTag),
                              ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _tagController,
                              style: TextStyle(fontSize: 11, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: '+ tag',
                                hintStyle: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                filled: true,
                                fillColor: isDark ? PinTokens.darkCardBg : PinTokens.lightTagBg,
                                border: OutlineInputBorder(
                                  borderRadius: PinTokens.radiusFull,
                                  borderSide: BorderSide(color: borderColor, width: 1.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: PinTokens.radiusFull,
                                  borderSide: BorderSide(color: borderColor, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: PinTokens.radiusFull,
                                  borderSide: BorderSide(
                                    color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  _addTag(val.trim());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Time Estimate
                      Text(
                        'Time Scope Estimate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _estimationOptions.map((minutes) {
                          final label = DateHelpers.formatMinutes(minutes);
                          final isSelected = _selectedEstimateMinutes == minutes;
                          return PillChip.duration(
                            durationText: label,
                            isSelected: isSelected,
                            onTap: () => setState(
                                () => _selectedEstimateMinutes = minutes),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Energy State
                      Text(
                        'Energy State',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _energyTags.map((tag) {
                          final isSelected = _selectedEnergyTag == tag;
                          return PillChip.energy(
                            tag: tag,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedEnergyTag = tag),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Atomic Steps Checklist
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Atomic Micro-Steps (Sub-15m)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              style: TextStyle(fontSize: 13, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Add micro action...',
                                hintStyle: TextStyle(
                                  color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: inputBg,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: PinTokens.radiusMd,
                                  borderSide: BorderSide(color: borderColor, width: 1.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: PinTokens.radiusMd,
                                  borderSide: BorderSide(color: borderColor, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: PinTokens.radiusMd,
                                  borderSide: BorderSide(
                                    color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PinButton(
                            icon: Icons.add_rounded,
                            text: 'Add',
                            isCompact: true,
                            onPressed: _addSubtask,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_subtasks.isNotEmpty)
                        Column(
                          children: _subtasks.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final step = entry.value;
                            return AtomicStepTile(
                              step: step,
                              isEditable: true,
                              onToggle: (val) {
                                setState(() {
                                  _subtasks[idx] =
                                      step.copyWith(isCompleted: val);
                                });
                              },
                              onDelete: () {
                                setState(() {
                                  _subtasks.removeAt(idx);
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PinButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  PinButton.primary(
                    text: isEditing ? 'Save Changes' : 'Pin to Deck',
                    icon: isEditing
                        ? Icons.check_rounded
                        : Icons.push_pin_rounded,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnOption({
    required String label,
    required TaskStatus status,
    required String badge,
    bool isFull = false,
    required Color borderColor,
    required Color textPrimary,
  }) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon = status == TaskStatus.today
        ? Icons.bolt_rounded
        : (status == TaskStatus.done
            ? Icons.check_circle_outline_rounded
            : Icons.inventory_2_outlined);

    final bgCol = isSelected
        ? (isDark ? const Color(0xFF1E2638) : PinTokens.lightSheetBg)
        : (isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg);

    final borderCol = isSelected
        ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg)
        : (isDark ? PinTokens.darkBorder : PinTokens.lightBorder);

    final iconCol = isSelected
        ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg)
        : (isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary);

    final labelCol = isSelected
        ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg)
        : (isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary);

    final badgeCol = isFull
        ? PinTokens.accentAmber
        : (isSelected
            ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightTextSecondary)
            : (isDark ? PinTokens.darkTextMuted : PinTokens.lightTextSecondary));

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = status),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: PinTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderCol,
              width: isSelected ? 1.2 : 1.0,
            ),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF1A241E).withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: iconCol,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: labelCol,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeCol,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
