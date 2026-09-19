import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../services/ai_config_service.dart';
import '../services/gemini_service.dart';
import 'ai_settings_modal.dart';

/// Modal dialog for re-analyzing an existing task with Gemini AI,
/// previewing decomposed atomic steps, and applying updates directly.
class AiTaskBreakdownModal extends ConsumerStatefulWidget {
  final PinTask task;
  final GeminiService? serviceOverride;
  final void Function(PinTask task)? onOpenEditor;

  const AiTaskBreakdownModal({
    super.key,
    required this.task,
    this.serviceOverride,
    this.onOpenEditor,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PinTask task,
    GeminiService? serviceOverride,
    void Function(PinTask task)? onOpenEditor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AiTaskBreakdownModal(
        task: task,
        serviceOverride: serviceOverride,
        onOpenEditor: onOpenEditor,
      ),
    );
  }

  @override
  ConsumerState<AiTaskBreakdownModal> createState() =>
      _AiTaskBreakdownModalState();
}

class _AiTaskBreakdownModalState extends ConsumerState<AiTaskBreakdownModal> {
  bool _isLoading = false;
  String? _errorMessage;
  AiTaskBreakdown? _breakdown;

  late String _refinedTitle;
  late String _refinedDescription;
  late String _energyTag;
  late int _estimatedMinutes;
  late List<String> _tags;
  late List<AtomicStep> _steps;

  final TextEditingController _newStepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refinedTitle = widget.task.title;
    _refinedDescription = widget.task.description;
    _energyTag = widget.task.energyTag;
    _estimatedMinutes = widget.task.estimatedMinutes;
    _tags = List.from(widget.task.tags);
    _steps = List.from(widget.task.subtasks);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBreakdown();
    });
  }

  @override
  void dispose() {
    _newStepController.dispose();
    super.dispose();
  }

  Future<void> _startBreakdown() async {
    final aiConfig = ref.read(aiConfigProvider);
    if (widget.serviceOverride == null && !aiConfig.hasKey) {
      final configured = await AiSettingsModal.show(context);
      if (configured != true || !mounted) return;
      if (!ref.read(aiConfigProvider).hasKey) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = widget.serviceOverride ?? GeminiService();
      final effectiveKey = ref.read(aiConfigProvider).apiKey.isNotEmpty
          ? ref.read(aiConfigProvider).apiKey
          : 'test_key';
      final result = await service.suggestTaskBreakdown(
        apiKey: effectiveKey,
        prompt: widget.task.title,
        currentDescription: widget.task.description.isNotEmpty
            ? widget.task.description
            : null,
        model: ref.read(aiConfigProvider).selectedModel,
      );

      if (mounted) {
        setState(() {
          _breakdown = result;
          _refinedTitle = result.title;
          _refinedDescription = result.description;
          _energyTag = result.energyTag;
          _estimatedMinutes = result.estimatedMinutes;
          _tags = List.from(result.tags);
          _steps = List.from(result.atomicSteps);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _addStep() {
    final text = _newStepController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _steps.add(
        AtomicStep(
          id: 'step_${DateTime.now().microsecondsSinceEpoch}',
          title: text,
          isCompleted: false,
          estimatedMinutes: 15,
        ),
      );
      _newStepController.clear();
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  Future<void> _applyToPin() async {
    final now = DateTime.now();
    final updatedTask = widget.task.copyWith(
      title: _refinedTitle,
      description: _refinedDescription,
      energyTag: _energyTag,
      estimatedMinutes: _estimatedMinutes,
      tags: _tags,
      subtasks: _steps,
      source: 'breakdown',
      updatedAt: now,
    );

    await ref.read(taskStateProvider.notifier).updateTask(updatedTask);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✨ Re-analyzed "${updatedTask.title}" with ${_steps.length} atomic steps!',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openInFullEditor() {
    final updatedTask = widget.task.copyWith(
      title: _refinedTitle,
      description: _refinedDescription,
      energyTag: _energyTag,
      estimatedMinutes: _estimatedMinutes,
      tags: _tags,
      subtasks: _steps,
      source: 'breakdown',
    );

    Navigator.of(context).pop(false);
    widget.onOpenEditor?.call(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final modalBg = isDark ? const Color(0xFF141824) : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Dialog(
      backgroundColor: modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusDeck,
        side: BorderSide(color: borderColor, width: isDark ? 1.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Breakdown & Re-Analysis',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Gemini decomposes tasks into bite-sized steps (≤15m each)',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _buildBody(isDark, textPrimary, textSecondary, borderColor),
              ),

              const SizedBox(height: 16),

              // Footer Actions
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  PinButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (_breakdown != null && !_isLoading) ...[
                    PinButton(
                      icon: Icons.tune_rounded,
                      text: 'Open Full Editor',
                      onPressed: _openInFullEditor,
                    ),
                    PinButton.primary(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Apply to Pin',
                      onPressed: _applyToPin,
                    ),
                  ] else if (_errorMessage != null) ...[
                    PinButton.primary(
                      icon: Icons.refresh_rounded,
                      text: 'Retry Analysis',
                      onPressed: _startBreakdown,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Analyzing "${widget.task.title}"...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Decomposing into atomic subtasks (≤ 15 mins) and refining focus properties...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
            borderRadius: PinTokens.radiusMd,
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 28),
              const SizedBox(height: 8),
              Text(
                'Failed to analyze task',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 12),
              PinButton(
                icon: Icons.key_rounded,
                text: 'Configure API Key',
                onPressed: () async {
                  await AiSettingsModal.show(context);
                  _startBreakdown();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Breakdown Preview View
    return ListView(
      children: [
        // Refined Title & Objective
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2030) : PinTokens.lightCanvasBg,
            borderRadius: PinTokens.radiusMd,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REFINED OBJECTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _refinedTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              if (_refinedDescription.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _refinedDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Metadata pills
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Energy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B4B) : PinTokens.energyDeepBg,
                      borderRadius: PinTokens.radiusFull,
                    ),
                    child: Text(
                      '⚡ ${_energyTag.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF818CF8) : PinTokens.energyDeepText,
                      ),
                    ),
                  ),

                  // Duration
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2330) : PinTokens.lightTagBg,
                      borderRadius: PinTokens.radiusFull,
                    ),
                    child: Text(
                      DateHelpers.formatMinutes(_estimatedMinutes),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),

                  // Tags
                  for (final tag in _tags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2330) : PinTokens.lightTagBg,
                        borderRadius: PinTokens.radiusFull,
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Atomic Steps List Header
        Row(
          children: [
            Text(
              'Atomic Subtasks (${_steps.length})',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: PinTokens.radiusFull,
              ),
              child: const Text(
                'each ≤ 15 min',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Steps List
        for (int i = 0; i < _steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181D2A) : PinTokens.lightCanvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : PinTokens.lightTagBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF818CF8) : PinTokens.lightFabBg,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _steps[i].title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                  splashRadius: 14,
                  color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                  tooltip: 'Remove step',
                  onPressed: () => _removeStep(i),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Add custom step field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newStepController,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add another atomic step...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E2330) : PinTokens.lightCanvasBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: PinTokens.radiusMd,
                    borderSide: BorderSide(color: borderColor),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _addStep(),
              ),
            ),
            const SizedBox(width: 8),
            PinButton(
              icon: Icons.add_rounded,
              text: 'Add',
              isCompact: true,
              onPressed: _addStep,
            ),
          ],
        ),
      ],
    );
  }
}
