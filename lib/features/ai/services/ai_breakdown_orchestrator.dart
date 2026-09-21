import 'ai_config_service.dart';
import 'gemini_service.dart';
import 'on_device_ai_service.dart';

import 'local_heuristic_breakdown_service.dart';

/// Result containing the decomposed Pin task and metadata about the execution engine.
class AiBreakdownResult {
  final AiTaskBreakdown breakdown;
  final bool isLocalOnDevice;
  final String engineTitle;
  final Duration duration;

  const AiBreakdownResult({
    required this.breakdown,
    required this.isLocalOnDevice,
    required this.engineTitle,
    required this.duration,
  });
}

/// Orchestrates task breakdown execution between On-Device Gemini Nano, Cloud Gemini,
/// and offline Smart Local Heuristic engine.
class AiBreakdownOrchestrator {
  final OnDeviceAiService _onDeviceService;
  final GeminiService _cloudService;
  final LocalHeuristicBreakdownService _localHeuristicService;

  AiBreakdownOrchestrator({
    OnDeviceAiService? onDeviceService,
    GeminiService? cloudService,
    LocalHeuristicBreakdownService? localHeuristicService,
  })  : _onDeviceService = onDeviceService ?? OnDeviceAiService(),
        _cloudService = cloudService ?? GeminiService(),
        _localHeuristicService =
            localHeuristicService ?? const LocalHeuristicBreakdownService();

  /// Executes task breakdown according to user execution preferences and device capability.
  Future<AiBreakdownResult> breakdown({
    required AiConfig config,
    required String prompt,
    String? currentDescription,
  }) async {
    final stopwatch = Stopwatch()..start();

    switch (config.executionMode) {
      case AiExecutionMode.onDeviceOnly:
        return _breakdownOnDevice(
          prompt: prompt,
          currentDescription: currentDescription,
          stopwatch: stopwatch,
          strict: true,
        );

      case AiExecutionMode.cloudOnly:
        return _breakdownCloud(
          config: config,
          prompt: prompt,
          currentDescription: currentDescription,
          stopwatch: stopwatch,
        );

      case AiExecutionMode.auto:
        // Try on-device Gemini Nano first if available on this device
        final capability = await _onDeviceService.checkCapability();
        if (capability.isReady) {
          try {
            return await _breakdownOnDevice(
              prompt: prompt,
              currentDescription: currentDescription,
              stopwatch: stopwatch,
              strict: false,
            );
          } catch (_) {
            // Seamlessly fall back to Cloud API if key is available
            if (config.hasKey) {
              return await _breakdownCloud(
                config: config,
                prompt: prompt,
                currentDescription: currentDescription,
                stopwatch: stopwatch,
              );
            }
          }
        }

        // On-device not ready: use Cloud Gemini API if key is configured
        if (config.hasKey) {
          return await _breakdownCloud(
            config: config,
            prompt: prompt,
            currentDescription: currentDescription,
            stopwatch: stopwatch,
          );
        }

        // Neither on-device nor API key is available: use Smart Local Engine
        return _breakdownLocalHeuristic(
          prompt: prompt,
          currentDescription: currentDescription,
          stopwatch: stopwatch,
        );
    }
  }

  AiBreakdownResult _breakdownLocalHeuristic({
    required String prompt,
    String? currentDescription,
    required Stopwatch stopwatch,
  }) {
    final breakdown = _localHeuristicService.decompose(
      prompt: prompt,
      currentDescription: currentDescription,
    );
    stopwatch.stop();

    return AiBreakdownResult(
      breakdown: breakdown,
      isLocalOnDevice: true,
      engineTitle: 'Smart Local Engine (Offline)',
      duration: stopwatch.elapsed,
    );
  }

  Future<AiBreakdownResult> _breakdownOnDevice({
    required String prompt,
    String? currentDescription,
    required Stopwatch stopwatch,
    required bool strict,
  }) async {
    final capability = await _onDeviceService.checkCapability();
    if (!capability.isReady) {
      if (strict) {
        throw GeminiApiException(
          'On-device Gemini Nano is not ready (${capability.message}). Please check AI Settings or switch execution mode to Auto.',
        );
      }
      throw GeminiApiException(capability.message);
    }

    final breakdown = await _onDeviceService.breakdownTaskOnDevice(
      prompt: prompt,
      currentDescription: currentDescription,
    );
    stopwatch.stop();

    return AiBreakdownResult(
      breakdown: breakdown,
      isLocalOnDevice: true,
      engineTitle: 'Gemini Nano (On-Device NPU)',
      duration: stopwatch.elapsed,
    );
  }

  Future<AiBreakdownResult> _breakdownCloud({
    required AiConfig config,
    required String prompt,
    String? currentDescription,
    required Stopwatch stopwatch,
  }) async {
    if (!config.hasKey) {
      throw const GeminiApiException(
        'Gemini API key is required for Cloud mode. Please configure it in AI Settings.',
      );
    }

    final breakdown = await _cloudService.suggestTaskBreakdown(
      apiKey: config.apiKey,
      prompt: prompt,
      currentDescription: currentDescription,
      model: config.selectedModel,
    );
    stopwatch.stop();

    return AiBreakdownResult(
      breakdown: breakdown,
      isLocalOnDevice: false,
      engineTitle: 'Cloud Gemini (${config.selectedModel})',
      duration: stopwatch.elapsed,
    );
  }
}
