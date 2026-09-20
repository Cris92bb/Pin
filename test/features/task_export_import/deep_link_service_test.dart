import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/features/task_export_import/services/deep_link_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PinTask sampleTask;

  setUp(() {
    final now = DateTime(2026, 9, 21, 10, 0);
    sampleTask = PinTask(
      id: 'task-link-test-1',
      title: 'Review PR & Deploy',
      description: 'Check regression tests and merge to develop',
      status: TaskStatus.today,
      category: 'deep_work',
      energyTag: 'deep-focus',
      intensity: 'focus',
      source: 'manual',
      estimatedMinutes: 30,
      trackedSeconds: 0,
      isPinned: true,
      tags: const ['release', 'dev'],
      subtasks: const [
        AtomicStep(id: 's1', title: 'Verify FSD rules', isCompleted: true),
        AtomicStep(id: 's2', title: 'Run flutter test', isCompleted: false),
      ],
      createdAt: now,
      updatedAt: now,
    );
  });

  tearDown(() {
    DeepLinkService.instance.dispose();
  });

  group('DeepLinkService URI Generation & Parsing', () {
    test('generateShareLink produces valid pin://import deep link', () {
      final link = DeepLinkService.generateShareLink(sampleTask);
      expect(link, startsWith('pin://import?blueprint=PIN_BP_'));

      final uri = Uri.parse(link);
      expect(uri.scheme, equals('pin'));
      expect(uri.host, equals('import'));
      expect(uri.queryParameters, contains('blueprint'));

      final parsedTasks = DeepLinkService.parseSharedTasks(uri);
      expect(parsedTasks.length, equals(1));
      expect(parsedTasks.first.title, equals('Review PR & Deploy'));
      expect(parsedTasks.first.estimatedMinutes, equals(30));
      expect(parsedTasks.first.tags, equals(['release', 'dev']));
      expect(parsedTasks.first.subtasks.length, equals(2));
    });

    test('generateBoardShareLink produces multi-task deep link', () {
      final task2 = sampleTask.copyWith(id: 'task-link-test-2', title: 'Second Pin');
      final link = DeepLinkService.generateBoardShareLink([sampleTask, task2]);
      expect(link, startsWith('pin://import?blueprint=PIN_BP_'));

      final uri = Uri.parse(link);
      final parsedTasks = DeepLinkService.parseSharedTasks(uri);
      expect(parsedTasks.length, equals(2));
      expect(parsedTasks[0].title, equals('Review PR & Deploy'));
      expect(parsedTasks[1].title, equals('Second Pin'));
    });

    test('parseSharedTasks handles web fragment query parameters', () {
      final link = DeepLinkService.generateShareLink(sampleTask);
      final blueprint = Uri.parse(link).queryParameters['blueprint']!;

      final webUri = Uri.parse('https://pin.app/#/import?blueprint=$blueprint');
      final parsedTasks = DeepLinkService.parseSharedTasks(webUri);

      expect(parsedTasks.length, equals(1));
      expect(parsedTasks.first.title, equals('Review PR & Deploy'));
    });

    test('parseSharedTasks gracefully returns empty list on empty or invalid URI', () {
      expect(DeepLinkService.parseSharedTasks(Uri.parse('pin://other')), isEmpty);
      expect(DeepLinkService.parseSharedTasks(Uri.parse('https://google.com')), isEmpty);
      expect(DeepLinkService.parseSharedTasks(Uri.parse('pin://import?blueprint=invalid')), isEmpty);
    });
  });

  group('DeepLinkService Platform Channel Integration', () {
    test('init processes cold start initial link and runtime onLinkReceived', () async {
      const channel = MethodChannel(DeepLinkService.channelName);
      final receivedLinks = <Uri>[];

      final sampleLink = DeepLinkService.generateShareLink(sampleTask);

      // Mock method channel handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialLink') {
          return sampleLink;
        }
        return null;
      });

      await DeepLinkService.instance.init(
        onLinkReceived: (uri) => receivedLinks.add(uri),
      );

      // Cold start link should have been delivered
      expect(receivedLinks.length, equals(1));
      expect(receivedLinks.first.toString(), equals(sampleLink));

      // Simulate runtime incoming link
      const runtimeLink = 'pin://import?blueprint=PIN_BP_runtime';
      final byteData = channel.codec.encodeMethodCall(const MethodCall('onLinkReceived', runtimeLink));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(DeepLinkService.channelName, byteData, (data) {});

      expect(receivedLinks.length, equals(2));
      expect(receivedLinks.last.toString(), equals(runtimeLink));
    });
  });
}
