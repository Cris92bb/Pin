import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/features/ai/services/ai_breakdown_orchestrator.dart';
import 'package:pin/features/ai/services/ai_config_service.dart';
import 'package:pin/features/ai/services/gemini_service.dart';
import 'package:pin/features/ai/services/on_device_ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeCloudGeminiService extends GeminiService {
  final AiTaskBreakdown breakdownToReturn;
  int callCount = 0;

  FakeCloudGeminiService(this.breakdownToReturn);

  @override
  Future<AiTaskBreakdown> suggestTaskBreakdown({
    required String apiKey,
    required String prompt,
    String? currentDescription,
    String model = 'gemini-3.6-flash',
  }) async {
    callCount++;
    return breakdownToReturn;
  }
}

void main() {
  const cannedBreakdown = AiTaskBreakdown(
    title: 'Decompose On-Device AI Flow',
    description: 'Breakdown test task objective',
    status: TaskStatus.today,
    energyTag: 'deep-focus',
    estimatedMinutes: 30,
    tags: ['#nano', '#dev'],
    atomicSteps: [
      AtomicStep(
        id: 'step_1',
        title: 'Check AICore availability',
        estimatedMinutes: 10,
        isCompleted: false,
      ),
      AtomicStep(
        id: 'step_2',
        title: 'Run on-device inference',
        estimatedMinutes: 10,
        isCompleted: false,
      ),
    ],
  );

  tearDown(() {
    OnDeviceAiService.mockCapability = null;
    OnDeviceAiService.mockGenerator = null;
  });

  group('OnDeviceAiCapability Tests', () {
    test('parses available status from map', () {
      final capability = OnDeviceAiCapability.fromMap({
        'status': 'available',
        'isSupported': true,
        'modelName': 'Gemini Nano',
        'deviceModel': 'Pixel 9 Pro',
        'manufacturer': 'Google',
        'isKnownFlagship': true,
        'isAiCoreInstalled': true,
        'message': 'Gemini Nano is available and hardware accelerated.',
      });

      expect(capability.status, OnDeviceAiStatus.ready);
      expect(capability.isReady, isTrue);
      expect(capability.isSupported, isTrue);
      expect(capability.deviceModel, 'Pixel 9 Pro');
      expect(capability.manufacturer, 'Google');
      expect(capability.isKnownSupportedDevice, isTrue);
    });

    test('parses downloadable status from map', () {
      final capability = OnDeviceAiCapability.fromMap({
        'status': 'downloadable',
        'isSupported': true,
        'deviceModel': 'SM-S928B',
        'manufacturer': 'samsung',
        'isKnownFlagship': true,
      });

      expect(capability.status, OnDeviceAiStatus.downloadable);
      expect(capability.isReady, isFalse);
      expect(capability.isSupported, isTrue);
    });

    test('unsupported returns proper status', () {
      final capability = OnDeviceAiCapability.unsupported(reason: 'Desktop Linux');
      expect(capability.status, OnDeviceAiStatus.unsupportedPlatform);
      expect(capability.isReady, isFalse);
      expect(capability.isSupported, isFalse);
      expect(capability.message, 'Desktop Linux');
    });
  });

  group('OnDeviceAiService Breakdown Parsing Tests', () {
    test('parses raw JSON correctly with clamping and hashtag normalization', () {
      const rawJson = '''
      {
        "title": "Refined Title From Nano",
        "description": "Clear objective scope",
        "energyTag": "DEEP-FOCUS",
        "estimatedMinutes": 32,
        "tags": ["mobile", "#ai"],
        "atomicSteps": [
          {"title": "Step 1", "estimatedMinutes": 25},
          {"title": "Step 2", "estimatedMinutes": 5}
        ]
      }
      ''';

      final result = OnDeviceAiService.parseOnDeviceBreakdown(rawJson, 'Fallback');
      expect(result.title, 'Refined Title From Nano');
      expect(result.description, 'Clear objective scope');
      expect(result.energyTag, 'deep-focus');
      // 32 maps to closest preset 30
      expect(result.estimatedMinutes, 30);
      expect(result.tags, containsAll(['#mobile', '#ai']));
      expect(result.atomicSteps.length, 2);
      // Clamped to max 15 minutes
      expect(result.atomicSteps[0].estimatedMinutes, 15);
      expect(result.atomicSteps[1].estimatedMinutes, 5);
    });

    test('strips markdown code fences before parsing', () {
      const markdownJson = '''
      ```json
      {
        "title": "Fenced Title",
        "description": "Inside markdown block",
        "energyTag": "medium-flow",
        "estimatedMinutes": 15,
        "tags": ["#nano"],
        "atomicSteps": [
          {"title": "Step 1", "estimatedMinutes": 10}
        ]
      }
      ```
      ''';

      final result = OnDeviceAiService.parseOnDeviceBreakdown(markdownJson, 'Fallback');
      expect(result.title, 'Fenced Title');
      expect(result.atomicSteps.length, 1);
    });
  });

  group('AiBreakdownOrchestrator Strategy Tests', () {
    test('Auto mode uses On-Device Gemini Nano when ready without API key', () async {
      OnDeviceAiService.mockCapability = const OnDeviceAiCapability(
        status: OnDeviceAiStatus.ready,
        isSupported: true,
        modelName: 'Gemini Nano',
        deviceModel: 'Pixel 9 Pro',
        manufacturer: 'Google',
        message: 'Ready',
      );

      OnDeviceAiService.mockGenerator = (prompt) async {
        return '''
        {
          "title": "Pixel 9 Nano Breakdown",
          "description": "Executed completely on-device NPU",
          "energyTag": "creative",
          "estimatedMinutes": 15,
          "tags": ["#pixel9", "#offline"],
          "atomicSteps": [
            {"title": "Local step", "estimatedMinutes": 5}
          ]
        }
        ''';
      };

      final cloudService = FakeCloudGeminiService(cannedBreakdown);
      final orchestrator = AiBreakdownOrchestrator(cloudService: cloudService);

      const config = AiConfig(
        apiKey: '', // No API key configured!
        selectedModel: 'gemini-3.6-flash',
        executionMode: AiExecutionMode.auto,
      );

      final result = await orchestrator.breakdown(
        config: config,
        prompt: 'Implement on-device task breakdown',
      );

      expect(result.isLocalOnDevice, isTrue);
      expect(result.engineTitle, contains('Gemini Nano'));
      expect(result.breakdown.title, 'Pixel 9 Nano Breakdown');
      expect(cloudService.callCount, 0); // Did not touch cloud API
    });

    test('Auto mode falls back to Cloud API when on-device is unavailable and API key exists', () async {
      OnDeviceAiService.mockCapability = OnDeviceAiCapability.unsupported(
        reason: 'Running on Linux desktop',
      );

      final cloudService = FakeCloudGeminiService(cannedBreakdown);
      final orchestrator = AiBreakdownOrchestrator(cloudService: cloudService);

      const config = AiConfig(
        apiKey: 'AIzaSyTestKey123',
        selectedModel: 'gemini-3.6-flash',
        executionMode: AiExecutionMode.auto,
      );

      final result = await orchestrator.breakdown(
        config: config,
        prompt: 'Implement on-device task breakdown',
      );

      expect(result.isLocalOnDevice, isFalse);
      expect(result.engineTitle, contains('Cloud Gemini'));
      expect(result.breakdown.title, cannedBreakdown.title);
      expect(cloudService.callCount, 1);
    });

    test('Auto mode throws informative exception when neither on-device nor API key is available', () async {
      OnDeviceAiService.mockCapability = OnDeviceAiCapability.unsupported(
        reason: 'Running on Linux desktop',
      );

      final cloudService = FakeCloudGeminiService(cannedBreakdown);
      final orchestrator = AiBreakdownOrchestrator(cloudService: cloudService);

      const config = AiConfig(
        apiKey: '',
        selectedModel: 'gemini-3.6-flash',
        executionMode: AiExecutionMode.auto,
      );

      expect(
        () => orchestrator.breakdown(
          config: config,
          prompt: 'Implement on-device task breakdown',
        ),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.message,
          'message',
          contains('Gemini API key is required'),
        )),
      );
    });

    test('OnDeviceOnly mode throws when model is not ready', () async {
      OnDeviceAiService.mockCapability = OnDeviceAiCapability.unsupported(
        reason: 'Device not supported',
      );

      final cloudService = FakeCloudGeminiService(cannedBreakdown);
      final orchestrator = AiBreakdownOrchestrator(cloudService: cloudService);

      const config = AiConfig(
        apiKey: 'AIzaSyTestKey123', // Has key, but mode is OnDeviceOnly!
        selectedModel: 'gemini-3.6-flash',
        executionMode: AiExecutionMode.onDeviceOnly,
      );

      expect(
        () => orchestrator.breakdown(
          config: config,
          prompt: 'Implement on-device task breakdown',
        ),
        throwsA(isA<GeminiApiException>().having(
          (e) => e.message,
          'message',
          contains('On-device Gemini Nano is not ready'),
        )),
      );
      expect(cloudService.callCount, 0);
    });

    test('Auto mode falls back to Cloud API if on-device inference throws and API key is present', () async {
      OnDeviceAiService.mockCapability = const OnDeviceAiCapability(
        status: OnDeviceAiStatus.ready,
        isSupported: true,
        modelName: 'Gemini Nano',
        message: 'Ready',
      );

      OnDeviceAiService.mockGenerator = (prompt) async {
        throw const GeminiApiException('AICore transient memory pressure');
      };

      final cloudService = FakeCloudGeminiService(cannedBreakdown);
      final orchestrator = AiBreakdownOrchestrator(cloudService: cloudService);

      const config = AiConfig(
        apiKey: 'AIzaSyValidKey',
        selectedModel: 'gemini-3.6-flash',
        executionMode: AiExecutionMode.auto,
      );

      final result = await orchestrator.breakdown(
        config: config,
        prompt: 'Handle fallback test',
      );

      expect(result.isLocalOnDevice, isFalse);
      expect(cloudService.callCount, 1);
    });
  });

  group('AiConfigNotifier Execution Mode Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads execution mode preference', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = AiConfigNotifier(prefs);

      expect(notifier.state.executionMode, AiExecutionMode.auto);

      await notifier.setExecutionMode(AiExecutionMode.onDeviceOnly);
      expect(notifier.state.executionMode, AiExecutionMode.onDeviceOnly);
      expect(prefs.getInt(AiConfigNotifier.executionModePref), AiExecutionMode.onDeviceOnly.index);

      // Re-create from prefs
      final reloadedNotifier = AiConfigNotifier(prefs);
      expect(reloadedNotifier.state.executionMode, AiExecutionMode.onDeviceOnly);
    });
  });
}
