import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'on_device_ai_service.dart';

/// Preference for selecting between On-Device Gemini Nano and Cloud Gemini API.
enum AiExecutionMode {
  /// Automatically use On-Device Gemini Nano if ready, fallback to Cloud API.
  auto,

  /// Strictly use On-Device Gemini Nano (private, offline, requires supported hardware).
  onDeviceOnly,

  /// Strictly use Cloud Gemini API with user-provided API key.
  cloudOnly,
}

/// Configuration state for AI features in Pin.
class AiConfig {
  final String apiKey;
  final String selectedModel;
  final AiExecutionMode executionMode;
  final OnDeviceAiCapability? onDeviceCapability;

  const AiConfig({
    required this.apiKey,
    required this.selectedModel,
    this.executionMode = AiExecutionMode.auto,
    this.onDeviceCapability,
  });

  bool get hasKey => apiKey.trim().isNotEmpty;
  bool get isOnDeviceReady => onDeviceCapability?.isReady == true;

  AiConfig copyWith({
    String? apiKey,
    String? selectedModel,
    AiExecutionMode? executionMode,
    OnDeviceAiCapability? onDeviceCapability,
  }) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      executionMode: executionMode ?? this.executionMode,
      onDeviceCapability: onDeviceCapability ?? this.onDeviceCapability,
    );
  }
}

/// Notifier managing AI configuration, persistence, and on-device capability checks.
class AiConfigNotifier extends Notifier<AiConfig> {
  static const String keyPref = 'pin_gemini_api_key';
  static const String modelPref = 'pin_gemini_model';
  static const String executionModePref = 'pin_ai_execution_mode';
  static const String defaultModel = 'gemini-3.6-flash';
  static const List<String> availableModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.7-flash',
    'gemini-3.8-flash',
  ];

  final SharedPreferences? _configuredPrefs;
  final OnDeviceAiService _onDeviceAiService;
  SharedPreferences? _prefs;
  AiConfig? _standaloneState;

  AiConfigNotifier([this._configuredPrefs, OnDeviceAiService? onDeviceService])
      : _onDeviceAiService = onDeviceService ?? OnDeviceAiService();

  @override
  AiConfig build() {
    _prefs = _configuredPrefs;
    if (_configuredPrefs != null) {
      final p = _configuredPrefs;
      final key = p.getString(keyPref) ?? '';
      var model = p.getString(modelPref) ?? defaultModel;
      if (!availableModels.contains(model)) model = defaultModel;
      final modeIndex = p.getInt(executionModePref) ?? AiExecutionMode.auto.index;
      final mode = (modeIndex >= 0 && modeIndex < AiExecutionMode.values.length)
          ? AiExecutionMode.values[modeIndex]
          : AiExecutionMode.auto;
      _checkCapability();
      return AiConfig(
        apiKey: key.trim(),
        selectedModel: model,
        executionMode: mode,
      );
    }
    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY');
    _loadFuture = _load();
    return AiConfig(
      apiKey: compileTimeKey.trim(),
      selectedModel: defaultModel,
      executionMode: AiExecutionMode.auto,
    );
  }

  Future<void>? _loadFuture;

  /// Ensures persisted preferences, environment keys, and hardware capabilities are fully loaded.
  Future<void> ensureLoaded() async {
    await (_loadFuture ??= _load());
  }

  @override
  AiConfig get state {
    try {
      return super.state;
    } catch (_) {
      return _standaloneState ??= build();
    }
  }

  @override
  set state(AiConfig value) {
    try {
      super.state = value;
    } catch (_) {
      _standaloneState = value;
    }
  }

  Future<void> _load() async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      String? key = p.getString(keyPref);

      // Fallback to compile-time env, system env, or .env file if available and not in prefs
      if (key == null || key.trim().isEmpty) {
        const compileKey = String.fromEnvironment('GEMINI_API_KEY');
        if (compileKey.trim().isNotEmpty) {
          key = compileKey.trim();
        } else if (!kIsWeb) {
          final envKey = Platform.environment['GEMINI_API_KEY'];
          if (envKey != null && envKey.trim().isNotEmpty) {
            key = envKey.trim();
          } else {
            try {
              final envFile = File('.env');
              if (envFile.existsSync()) {
                final lines = envFile.readAsLinesSync();
                for (final line in lines) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('GEMINI_API_KEY=')) {
                    final val = trimmed.substring('GEMINI_API_KEY='.length).trim();
                    if (val.isNotEmpty) {
                      key = val.replaceAll('"', '').replaceAll("'", '');
                      break;
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }
      }

      var model = p.getString(modelPref);
      if (model == null ||
          model == 'gemini-2.5-flash' ||
          model == 'gemini-1.5-flash' ||
          model == 'gemini-2.0-flash' ||
          !availableModels.contains(model)) {
        model = defaultModel;
        await p.setString(modelPref, defaultModel);
      }

      final modeIndex = p.getInt(executionModePref) ?? AiExecutionMode.auto.index;
      final mode = (modeIndex >= 0 && modeIndex < AiExecutionMode.values.length)
          ? AiExecutionMode.values[modeIndex]
          : AiExecutionMode.auto;

      state = AiConfig(
        apiKey: key?.trim() ?? '',
        selectedModel: model,
        executionMode: mode,
      );

      // Check on-device capability and await so ensureLoaded captures it
      await _checkCapability();
    } catch (_) {
      // Gracefully ignore local read errors
    }
  }

  Future<void> _checkCapability() async {
    try {
      final capability = await _onDeviceAiService.checkCapability();
      state = state.copyWith(onDeviceCapability: capability);
    } catch (_) {}
  }

  Future<void> refreshCapability() async {
    await _checkCapability();
  }

  Future<void> setApiKey(String newKey) async {
    final trimmed = newKey.trim();
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      if (trimmed.isEmpty) {
        await p.remove(keyPref);
      } else {
        await p.setString(keyPref, trimmed);
      }
    } catch (_) {}
    state = state.copyWith(apiKey: trimmed);
  }

  Future<void> setModel(String model) async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      await p.setString(modelPref, model);
    } catch (_) {}
    state = state.copyWith(selectedModel: model);
  }

  Future<void> setExecutionMode(AiExecutionMode mode) async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      await p.setInt(executionModePref, mode.index);
    } catch (_) {}
    state = state.copyWith(executionMode: mode);
  }

  Future<void> clearApiKey() async {
    await setApiKey('');
  }
}

final aiConfigProvider =
    NotifierProvider<AiConfigNotifier, AiConfig>(AiConfigNotifier.new);
