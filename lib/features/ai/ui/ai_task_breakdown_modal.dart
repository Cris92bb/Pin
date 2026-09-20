import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../services/ai_breakdown_orchestrator.dart';
import '../services/ai_config_service.dart';
import '../services/gemini_service.dart';
import 'ai_settings_modal.dart';
import 'components/breakdown_modal_chrome.dart';
import 'components/breakdown_status_views.dart';
import 'components/breakdown_steps_list.dart';
import 'components/refined_objective_card.dart';

/// Modal dialog for decomposing an existing task with Gemini AI (On-Device or Cloud),
/// previewing decomposed atomic steps, and applying updates directly.
class AiTaskBreakdownModal extends ConsumerStatefulWidget {
  final PinTask task;
  final GeminiService? serviceOverride;
  final AiBreakdownOrchestrator? orchestratorOverride;
  final void Function(PinTask task)? onOpenEditor;

  const AiTaskBreakdownModal({
    super.key,
    required this.task,
    this.serviceOverride,
    this.orchestratorOverride,
    this.onOpenEditor,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PinTask task,
    GeminiService? serviceOverride,
    AiBreakdownOrchestrator? orchestratorOverride,
    void Function(PinTask task)? onOpenEditor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AiTaskBreakdownModal(
        task: task,
        serviceOverride: serviceOverride,
        orchestratorOverride: orchestratorOverride,
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
  bool _isLocalOnDevice = false;
  String? _engineTitle;
  Duration? _duration;

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
    final canRunLocally = aiConfig.isOnDeviceReady &&
        aiConfig.executionMode != AiExecutionMode.cloudOnly;

    if (widget.serviceOverride == null &&
        widget.orchestratorOverride == null &&
        !aiConfig.hasKey &&
        !canRunLocally) {
      final configured = await AiSettingsModal.show(context);
      if (configured != true || !mounted) return;
      final updated = ref.read(aiConfigProvider);
      if (!updated.hasKey && !updated.isOnDeviceReady) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final effectiveConfig = (ref.read(aiConfigProvider).apiKey.isEmpty && widget.serviceOverride != null)
          ? ref.read(aiConfigProvider).copyWith(apiKey: 'test_key')
          : ref.read(aiConfigProvider);

      final orchestrator = widget.orchestratorOverride ??
          AiBreakdownOrchestrator(cloudService: widget.serviceOverride);

      final result = await orchestrator.breakdown(
        config: effectiveConfig,
        prompt: widget.task.title,
        currentDescription: widget.task.description.isNotEmpty
            ? widget.task.description
            : null,
      );

      if (mounted) {
        setState(() {
          _isLocalOnDevice = result.isLocalOnDevice;
          _engineTitle = result.engineTitle;
          _duration = result.duration;
          _refinedTitle = result.breakdown.title;
          _refinedDescription = result.breakdown.description;
          _energyTag = result.breakdown.energyTag;
          _estimatedMinutes = result.breakdown.estimatedMinutes;
          _tags = List.from(result.breakdown.tags);
          _steps = List.from(result.breakdown.atomicSteps);
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
    setState(() => _steps.removeAt(index));
  }

  Future<void> _applyToPin() async {
    final updatedTask = widget.task.copyWith(
      title: _refinedTitle,
      description: _refinedDescription,
      energyTag: _energyTag,
      estimatedMinutes: _estimatedMinutes,
      tags: _tags,
      subtasks: _steps,
      source: 'breakdown',
      updatedAt: DateTime.now(),
    );

    await ref.read(taskStateProvider.notifier).updateTask(updatedTask);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Re-analyzed "${updatedTask.title}" with ${_steps.length} atomic steps!',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

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
              BreakdownModalHeader(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                isLocalOnDevice: _isLocalOnDevice,
                engineTitle: _engineTitle,
                duration: _duration,
                onClose: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? BreakdownLoadingView(taskTitle: widget.task.title)
                    : _errorMessage != null
                        ? BreakdownErrorView(
                            errorMessage: _errorMessage!,
                            onOpenSettings: () async {
                              await AiSettingsModal.show(context);
                              _startBreakdown();
                            },
                          )
                        : _buildPreviewState(),
              ),
              const SizedBox(height: 16),
              BreakdownModalActions(
                onOpenFullEditor: _openInFullEditor,
                onCancel: () => Navigator.of(context).pop(false),
                onApply: _applyToPin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    return ListView(
      children: [
        RefinedObjectiveCard(
          title: _refinedTitle,
          description: _refinedDescription,
          energyTag: _energyTag,
          estimatedMinutes: _estimatedMinutes,
          tags: _tags,
        ),
        const SizedBox(height: 16),
        BreakdownStepsList(
          steps: _steps,
          newStepController: _newStepController,
          onAddStep: _addStep,
          onRemoveStep: _removeStep,
        ),
      ],
    );
  }
}
