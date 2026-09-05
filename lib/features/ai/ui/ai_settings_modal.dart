import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../services/ai_config_service.dart';
import '../services/gemini_service.dart';

/// Modal dialog for managing the Gemini API key and model selection.
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
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResultSuccess;
  String? _testResultError;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _keyController = TextEditingController(text: config.apiKey);
    _selectedModel = config.selectedModel;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
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
          _testResultSuccess = 'Successfully connected to Gemini ($_selectedModel)!';
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
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final key = _keyController.text.trim();
    await ref.read(aiConfigProvider.notifier).setApiKey(key);
    await ref.read(aiConfigProvider.notifier).setModel(_selectedModel);
    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            key.isEmpty
                ? 'Gemini API key cleared.'
                : 'Gemini settings saved successfully.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final cardBg = isDark ? PinTokens.darkCardBg : Colors.white;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final surfaceBg = isDark ? Colors.white.withValues(alpha: 0.04) : PinTokens.lightTagBg;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusLg,
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: PinTokens.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: PinTokens.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini AI Settings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Task decomposition & auto-fill',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // API Key field label & link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'GEMINI API KEY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'aistudio.google.com',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: PinTokens.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // API Key text input
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: PinTokens.radiusMd,
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: PinTokens.radiusMd,
                    borderSide: BorderSide(color: PinTokens.primary, width: 1.5),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        color: textSecondary,
                        onPressed: () {
                          setState(() {
                            _obscureKey = !_obscureKey;
                          });
                        },
                      ),
                      if (_keyController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          color: textSecondary,
                          onPressed: () {
                            setState(() {
                              _keyController.clear();
                              _testResultError = null;
                              _testResultSuccess = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                onChanged: (_) {
                  if (_testResultError != null || _testResultSuccess != null) {
                    setState(() {
                      _testResultError = null;
                      _testResultSuccess = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Model selector
              Text(
                'MODEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: PinTokens.radiusMd,
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    items: AiConfigNotifier.availableModels.map((m) {
                      final label = m == 'gemini-1.5-flash'
                          ? '$m (Recommended)'
                          : m;
                      return DropdownMenuItem<String>(
                        value: m,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedModel = val;
                          _testResultError = null;
                          _testResultSuccess = null;
                        });
                      }
                    },
                  ),
                ),
              ),

              // Status messages (success or error)
              if (_testResultSuccess != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: PinTokens.radiusMd,
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResultSuccess!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_testResultError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: PinTokens.radiusMd,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResultError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: PinTokens.radiusMd,
                      ),
                    ),
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(PinTokens.primary),
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(
                      _isTesting ? 'Testing...' : 'Test',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  PinButton.primary(
                    text: 'Save',
                    icon: Icons.check_rounded,
                    onPressed: _saveSettings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
