import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import 'gemini_service.dart';

/// Status of the on-device Gemini Nano model on this device.
enum OnDeviceAiStatus {
  /// Gemini Nano is downloaded, hardware-accelerated, and ready for inference.
  ready,

  /// Gemini Nano is supported on this hardware (e.g., Pixel 9+, Samsung S24+)
  /// but the AICore model is not yet downloaded.
  downloadable,

  /// Gemini Nano model download is currently in progress.
  downloading,

  /// Hardware or OS does not support Gemini Nano.
  unavailable,

  /// Platform is not Android (e.g. Linux desktop, Web, macOS, Windows, iOS).
  unsupportedPlatform,
}

/// Detailed capabilities and hardware status of on-device AI.
class OnDeviceAiCapability {
  final OnDeviceAiStatus status;
  final bool isSupported;
  final String modelName;
  final String? deviceModel;
  final String? manufacturer;
  final bool isKnownSupportedDevice;
  final bool isAiCoreInstalled;
  final String message;

  const OnDeviceAiCapability({
    required this.status,
    required this.isSupported,
    this.modelName = 'Gemini Nano',
    this.deviceModel,
    this.manufacturer,
    this.isKnownSupportedDevice = false,
    this.isAiCoreInstalled = false,
    required this.message,
  });

  bool get isReady => status == OnDeviceAiStatus.ready;

  factory OnDeviceAiCapability.unsupported({required String reason}) {
    return OnDeviceAiCapability(
      status: OnDeviceAiStatus.unsupportedPlatform,
      isSupported: false,
      message: reason,
    );
  }

  factory OnDeviceAiCapability.fromMap(Map<dynamic, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'unavailable';
    final OnDeviceAiStatus status;
    switch (statusStr) {
      case 'available':
        status = OnDeviceAiStatus.ready;
        break;
      case 'downloadable':
        status = OnDeviceAiStatus.downloadable;
        break;
      case 'downloading':
        status = OnDeviceAiStatus.downloading;
        break;
      default:
        status = OnDeviceAiStatus.unavailable;
    }

    return OnDeviceAiCapability(
      status: status,
      isSupported: map['isSupported'] as bool? ?? false,
      modelName: map['modelName'] as String? ?? 'Gemini Nano',
      deviceModel: map['deviceModel'] as String?,
      manufacturer: map['manufacturer'] as String?,
      isKnownSupportedDevice: map['isKnownFlagship'] as bool? ?? false,
      isAiCoreInstalled: map['isAiCoreInstalled'] as bool? ?? false,
      message: map['message'] as String? ?? 'Capability queried',
    );
  }
}

/// Service interface to interact with On-Device Gemini Nano on Android via AICore.
class OnDeviceAiService {
  static const MethodChannel _channel =
      MethodChannel('com.example.pin/on_device_ai');

  /// Optional mock capability for testing without native Android devices.
  static OnDeviceAiCapability? mockCapability;

  /// Optional mock generator for testing inference responses.
  static Future<String> Function(String prompt)? mockGenerator;

  /// Queries whether the host platform and device hardware support Gemini Nano.
  Future<OnDeviceAiCapability> checkCapability() async {
    if (mockCapability != null) {
      return mockCapability!;
    }

    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return OnDeviceAiCapability.unsupported(
        reason:
            'On-Device Gemini Nano is designed for Pixel 9+ and flagship Samsung Galaxy devices running Android AICore.',
      );
    }

    try {
      final dynamic raw = await _channel.invokeMethod('checkCapability');
      if (raw is Map) {
        return OnDeviceAiCapability.fromMap(raw);
      }
      return OnDeviceAiCapability.unsupported(
        reason: 'Unexpected response from AICore platform channel.',
      );
    } catch (e) {
      return OnDeviceAiCapability(
        status: OnDeviceAiStatus.unavailable,
        isSupported: false,
        message: 'Unable to query AICore: $e',
      );
    }
  }

  /// Triggers on-device model download if [OnDeviceAiStatus.downloadable].
  Future<bool> downloadModel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final res = await _channel.invokeMethod<bool>('downloadModel');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Executes Pin task breakdown directly on-device using Gemini Nano.
  Future<AiTaskBreakdown> breakdownTaskOnDevice({
    required String prompt,
    String? currentDescription,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw const GeminiApiException(
        'Please enter a task title or description to analyze',
      );
    }

    const systemInstruction =
        'You are an expert productivity companion for Pin, a minimalist Kanban app. '
        'Analyze the user\'s task prompt, refine the title to be crisp and actionable, '
        'generate a clear concise objective description, assess appropriate energy level '
        'from [low-friction, medium-flow, deep-focus, creative, administrative], '
        'estimated total duration in minutes [5, 15, 30, 45, 60, 120], '
        'suggest 1-4 hashtags (e.g. #dev, #ui, #fix), and break down into 2-6 bite-sized '
        'atomic steps (each <= 15 minutes).\n'
        'CRITICAL: Return ONLY valid JSON without markdown fences matching:\n'
        '{"title":"...","description":"...","energyTag":"medium-flow","estimatedMinutes":30,'
        '"tags":["#dev"],"atomicSteps":[{"title":"...","estimatedMinutes":10}]}';

    final fullPrompt = '$systemInstruction\n\n'
        'TASK: $cleanPrompt\n'
        'EXISTING DETAILS: ${currentDescription?.trim() ?? "None"}';

    final String rawResponse;
    if (mockGenerator != null) {
      rawResponse = await mockGenerator!(fullPrompt);
    } else {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        throw const GeminiApiException(
          'On-device AI is only available on supported Android devices.',
        );
      }

      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'generatePrompt',
        {'prompt': fullPrompt},
      );

      rawResponse = (res?['text'] as String?) ?? '';
    }

    if (rawResponse.trim().isEmpty) {
      throw const GeminiApiException('On-device Gemini Nano returned empty text.');
    }

    return parseOnDeviceBreakdown(rawResponse, cleanPrompt);
  }

  /// Parses raw JSON text (handling optional markdown fences) into [AiTaskBreakdown].
  static AiTaskBreakdown parseOnDeviceBreakdown(
    String rawText,
    String fallbackTitle,
  ) {
    String cleaned = rawText.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // Extract first {...} block if there are leading/trailing explanations
    final startIdx = cleaned.indexOf('{');
    final endIdx = cleaned.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    final dynamic decoded = jsonDecode(cleaned);
    if (decoded is! Map<String, dynamic>) {
      throw const GeminiApiException(
        'On-device model returned invalid JSON structure.',
      );
    }

    final title = (decoded['title'] as String?)?.trim().isNotEmpty == true
        ? (decoded['title'] as String).trim()
        : fallbackTitle;

    final description = (decoded['description'] as String?)?.trim() ?? '';

    String energyTag =
        (decoded['energyTag'] as String?)?.toLowerCase().trim() ?? 'medium-flow';
    if (!GeminiService.validEnergyTags.contains(energyTag)) {
      energyTag = 'medium-flow';
    }

    final rawMinutes = (decoded['estimatedMinutes'] as num?)?.toInt() ?? 30;
    final estimatedMinutes = GeminiService.validEstimateOptions.reduce(
      (curr, next) =>
          (curr - rawMinutes).abs() < (next - rawMinutes).abs() ? curr : next,
    );

    final rawTags = decoded['tags'];
    final List<String> tags = [];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is String && t.trim().isNotEmpty) {
          final clean = t.trim().startsWith('#') ? t.trim() : '#${t.trim()}';
          if (!tags.contains(clean)) {
            tags.add(clean);
          }
        }
      }
    }
    if (tags.isEmpty) tags.add('#dev');

    final rawSteps = decoded['atomicSteps'];
    final List<AtomicStep> atomicSteps = [];
    if (rawSteps is List) {
      int stepIdx = 0;
      for (final s in rawSteps) {
        if (s is Map<String, dynamic>) {
          final stepTitle = (s['title'] as String?)?.trim() ?? '';
          if (stepTitle.isEmpty) continue;
          final rawStepMin = (s['estimatedMinutes'] as num?)?.toInt() ?? 10;
          final clampedMinutes = rawStepMin.clamp(1, 15);

          atomicSteps.add(
            AtomicStep(
              id: 'nano_step_${DateTime.now().millisecondsSinceEpoch}_${stepIdx++}',
              title: stepTitle,
              estimatedMinutes: clampedMinutes,
              isCompleted: false,
            ),
          );
        }
      }
    }

    return AiTaskBreakdown(
      title: title,
      description: description,
      status: TaskStatus.today,
      energyTag: energyTag,
      estimatedMinutes: estimatedMinutes,
      tags: tags,
      atomicSteps: atomicSteps,
    );
  }
}
