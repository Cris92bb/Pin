import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConfig {
  final String apiKey;
  final String selectedModel;

  const AiConfig({
    required this.apiKey,
    required this.selectedModel,
  });

  bool get hasKey => apiKey.trim().isNotEmpty;

  AiConfig copyWith({
    String? apiKey,
    String? selectedModel,
  }) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}

class AiConfigNotifier extends Notifier<AiConfig> {
  static const String keyPref = 'pin_gemini_api_key';
  static const String modelPref = 'pin_gemini_model';
  static const String defaultModel = 'gemini-3.6-flash';
  static const List<String> availableModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.7-flash',
    'gemini-3.8-flash',
  ];

  final SharedPreferences? _configuredPrefs;
  SharedPreferences? _prefs;
  AiConfig? _standaloneState;

  AiConfigNotifier([this._configuredPrefs]);

  @override
  AiConfig build() {
    _prefs = _configuredPrefs;
    _load();
    return const AiConfig(apiKey: '', selectedModel: defaultModel);
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

      // Fallback to environment variable or .env file if available and not configured in prefs
      if ((key == null || key.trim().isEmpty) && !kIsWeb) {
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

      var model = p.getString(modelPref);
      if (model == null ||
          model == 'gemini-2.5-flash' ||
          model == 'gemini-1.5-flash' ||
          model == 'gemini-2.0-flash' ||
          !availableModels.contains(model)) {
        model = defaultModel;
        await p.setString(modelPref, defaultModel);
      }

      state = AiConfig(apiKey: key?.trim() ?? '', selectedModel: model);
    } catch (_) {
      // Gracefully ignore local read errors
    }
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

  Future<void> clearApiKey() async {
    await setApiKey('');
  }
}

final aiConfigProvider =
    NotifierProvider<AiConfigNotifier, AiConfig>(AiConfigNotifier.new);
