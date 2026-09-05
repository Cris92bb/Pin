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

class AiConfigNotifier extends StateNotifier<AiConfig> {
  static const String keyPref = 'pin_gemini_api_key';
  static const String modelPref = 'pin_gemini_model';
  static const String defaultModel = 'gemini-1.5-flash';
  static const List<String> availableModels = [
    'gemini-1.5-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  final SharedPreferences? _prefs;

  AiConfigNotifier([this._prefs])
      : super(const AiConfig(apiKey: '', selectedModel: defaultModel)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      String? key = p.getString(keyPref);

      // Fallback to environment variable if available and not configured in prefs
      if ((key == null || key.trim().isEmpty) && !kIsWeb) {
        final envKey = Platform.environment['GEMINI_API_KEY'];
        if (envKey != null && envKey.trim().isNotEmpty) {
          key = envKey.trim();
        }
      }

      final model = p.getString(modelPref) ?? defaultModel;
      state = AiConfig(apiKey: key?.trim() ?? '', selectedModel: model);
    } catch (_) {
      // Gracefully ignore local read errors
    }
  }

  Future<void> setApiKey(String newKey) async {
    final trimmed = newKey.trim();
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
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
      await p.setString(modelPref, model);
    } catch (_) {}
    state = state.copyWith(selectedModel: model);
  }

  Future<void> clearApiKey() async {
    await setApiKey('');
  }
}

final aiConfigProvider = StateNotifierProvider<AiConfigNotifier, AiConfig>((ref) {
  return AiConfigNotifier();
});
