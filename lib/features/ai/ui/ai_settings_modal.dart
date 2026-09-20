import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../services/ai_config_service.dart';
import '../services/gemini_service.dart';
import '../services/on_device_ai_service.dart';
import 'components/ai_settings_feedback_banner.dart';
import 'components/ai_settings_footer_actions.dart';
import 'components/cloud_gemini_config_section.dart';
import 'components/execution_mode_selector.dart';
import 'components/on_device_ai_status_card.dart';

/// Modal dialog for configuring On-Device Gemini Nano and Cloud Gemini settings.
class AiSettingsModal extends ConsumerStatefulWidget {
  const AiSettingsModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const AiSettingsModal(),
    );
  }

  @override
  ConsumerState<AiSettingsModal> createState() => _AiSettingsModalState();
}

class _AiSettingsModalState extends ConsumerState<AiSettingsModal> {
  late final TextEditingController _keyController;
  late String _selectedModel;
  late AiExecutionMode _executionMode;
  bool _obscureKey = true;
  bool _isTesting = false;
  bool _isCheckingCapability = false;
  String? _testResultSuccess;
  String? _testResultError;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _keyController = TextEditingController(text: config.apiKey);
    _selectedModel = config.selectedModel;
    _executionMode = config.executionMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCapability();
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _refreshCapability() async {
    setState(() => _isCheckingCapability = true);
    await ref.read(aiConfigProvider.notifier).refreshCapability();
    if (mounted) {
      setState(() => _isCheckingCapability = false);
    }
  }

  Future<void> _downloadModel() async {
    setState(() => _isCheckingCapability = true);
    final success = await OnDeviceAiService().downloadModel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Gemini Nano download initiated via AICore.'
                : 'Could not initiate download.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      await _refreshCapability();
    }
  }

  Future<void> _testOnDevice() async {
    setState(() {
      _isTesting = true;
      _testResultError = null;
      _testResultSuccess = null;
    });

    try {
      final breakdown = await OnDeviceAiService().breakdownTaskOnDevice(
        prompt: 'Test Gemini Nano on-device connection',
      );
      if (mounted) {
        setState(() {
          _testResultSuccess =
              '⚡ On-device Gemini Nano responded in real-time! (${breakdown.atomicSteps.length} steps generated)';
          _testResultError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResultError = e.toString();
          _testResultSuccess = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _testCloudConnection() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testResultError = 'Please enter an API key first.';
        _testResultSuccess = null;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResultError = null;
      _testResultSuccess = null;
    });

    try {
      final service = GeminiService();
      await service.testConnection(key, model: _selectedModel);
      if (mounted) {
        setState(() {
          _testResultSuccess = 'Successfully connected to Gemini Cloud ($_selectedModel)!';
          _testResultError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResultError = e.toString();
          _testResultSuccess = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final key = _keyController.text.trim();
    await ref.read(aiConfigProvider.notifier).setApiKey(key);
    await ref.read(aiConfigProvider.notifier).setModel(_selectedModel);
    await ref.read(aiConfigProvider.notifier).setExecutionMode(_executionMode);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini settings saved successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

    final config = ref.watch(aiConfigProvider);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusDeck,
        side: BorderSide(color: borderColor, width: isDark ? 1.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, textPrimary, textSecondary, isDark),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OnDeviceAiStatusCard(
                        capability: config.onDeviceCapability,
                        isChecking: _isCheckingCapability,
                        onRefresh: _refreshCapability,
                        onDownload: _downloadModel,
                        onTest: _testOnDevice,
                      ),
                      const SizedBox(height: 16),
                      ExecutionModeSelector(
                        currentMode: _executionMode,
                        onModeChanged: (mode) => setState(() => _executionMode = mode),
                      ),
                      const SizedBox(height: 16),
                      CloudGeminiConfigSection(
                        controller: _keyController,
                        obscureKey: _obscureKey,
                        onToggleObscure: () => setState(() => _obscureKey = !_obscureKey),
                        selectedModel: _selectedModel,
                        availableModels: AiConfigNotifier.availableModels,
                        onModelChanged: (model) => setState(() => _selectedModel = model),
                      ),
                      if (_testResultSuccess != null || _testResultError != null) ...[
                        const SizedBox(height: 12),
                        AiSettingsFeedbackBanner(
                          successMessage: _testResultSuccess,
                          errorMessage: _testResultError,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AiSettingsFooterActions(
                isTesting: _isTesting,
                onTestCloud: _testCloudConnection,
                onCancel: () => Navigator.of(context).pop(),
                onSave: _saveSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primary, Color secondary, bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? PinTokens.darkEnergyLowBg : PinTokens.lightSheetBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: isDark ? PinTokens.darkEnergyLowText : PinTokens.lightActiveFocus,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gemini AI Settings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary),
              ),
              Text(
                'On-Device Nano & Cloud Gemini breakdown',
                style: TextStyle(fontSize: 12, color: secondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 20, color: secondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
