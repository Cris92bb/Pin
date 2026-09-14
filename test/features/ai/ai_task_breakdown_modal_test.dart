import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/ai/services/gemini_service.dart';
import 'package:pin/features/ai/ui/ai_task_breakdown_modal.dart';
import 'package:pin/features/task_crud/ui/task_crud_modal.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGeminiService extends GeminiService {
  final AiTaskBreakdown cannedResponse;

  FakeGeminiService(this.cannedResponse);

  @override
  Future<AiTaskBreakdown> suggestTaskBreakdown({
    required String apiKey,
    required String prompt,
    String? currentDescription,
    String model = 'gemini-3.6-flash',
  }) async {
    return cannedResponse;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'pin_gemini_api_key': 'AIzaFakeKeyForTesting12345',
      'pin_gemini_model': 'gemini-3.6-flash',
    });
  });

  final testTask = PinTask(
    id: 'test_task_ai_1',
    title: 'Implement Dark Mode',
    description: 'Ensure all views support high contrast dark themes',
    status: TaskStatus.today,
    energyTag: 'medium-flow',
    estimatedMinutes: 45,
    tags: ['#theme'],
    subtasks: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  const cannedBreakdown = AiTaskBreakdown(
    title: 'Architect Crisp AMOLED Dark Theme System',
    description: 'Configure high contrast tokens, card backgrounds, and font hierarchy',
    energyTag: 'deep-focus',
    estimatedMinutes: 30,
    tags: ['#theme', '#ui', '#amoled'],
    atomicSteps: [
      AtomicStep(
        id: 'step_1',
        title: 'Audit PinTokens for dark borders & card backgrounds',
        isCompleted: false,
        estimatedMinutes: 10,
      ),
      AtomicStep(
        id: 'step_2',
        title: 'Configure MaterialApp theme switching logic',
        isCompleted: false,
        estimatedMinutes: 10,
      ),
      AtomicStep(
        id: 'step_3',
        title: 'Verify tactile card shadows on dark surface',
        isCompleted: false,
        estimatedMinutes: 10,
      ),
    ],
  );

  testWidgets('AiTaskBreakdownModal decomposes task and previews atomic steps', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();
    final fakeService = FakeGeminiService(cannedBreakdown);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: AiTaskBreakdownModal(
              task: testTask,
              serviceOverride: fakeService,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and decomposition results
    expect(find.text('AI Breakdown & Re-Analysis'), findsOneWidget);
    expect(find.text('Architect Crisp AMOLED Dark Theme System'), findsOneWidget);
    expect(find.textContaining('Atomic Subtasks (3)'), findsOneWidget);
    expect(find.text('Audit PinTokens for dark borders & card backgrounds'), findsOneWidget);
    expect(find.text('Configure MaterialApp theme switching logic'), findsOneWidget);
    expect(find.text('Verify tactile card shadows on dark surface'), findsOneWidget);

    // Verify metadata pills
    expect(find.text('⚡ DEEP-FOCUS'), findsOneWidget);
    expect(find.text('#amoled'), findsOneWidget);
  });

  testWidgets('AiTaskBreakdownModal Apply to Pin updates task in state notifier', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter([testTask.toJson()]);
    final fakeService = FakeGeminiService(cannedBreakdown);
    final notifier = TaskStateNotifier(
      storage: fakeStorage,
      seedInitialSample: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AiTaskBreakdownModal.show(
                    context,
                    task: testTask,
                    serviceOverride: fakeService,
                  );
                },
                child: const Text('Launch AI Breakdown'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open modal
    await tester.tap(find.text('Launch AI Breakdown'));
    await tester.pumpAndSettle();

    // Tap Apply to Pin
    final applyButton = find.text('Apply to Pin');
    expect(applyButton, findsOneWidget);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Verify modal closed
    expect(find.byType(AiTaskBreakdownModal), findsNothing);

    // Verify task updated in state
    final updated = notifier.state.tasks.firstWhere((t) => t.id == testTask.id);
    expect(updated.title, 'Architect Crisp AMOLED Dark Theme System');
    expect(updated.subtasks.length, 3);
    expect(updated.source, 'breakdown');
    expect(updated.energyTag, 'deep-focus');
  });

  testWidgets('AiTaskBreakdownModal Open Full Editor opens TaskCrudModal', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();
    final fakeService = FakeGeminiService(cannedBreakdown);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AiTaskBreakdownModal.show(
                    context,
                    task: testTask,
                    serviceOverride: fakeService,
                    onOpenEditor: (t) => TaskCrudModal.show(context, task: t),
                  );
                },
                child: const Text('Launch AI Breakdown'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open modal
    await tester.tap(find.text('Launch AI Breakdown'));
    await tester.pumpAndSettle();

    // Tap Open Full Editor
    final fullEditorButton = find.text('Open Full Editor');
    expect(fullEditorButton, findsOneWidget);
    await tester.tap(fullEditorButton);
    await tester.pumpAndSettle();

    // Verify TaskCrudModal is now open with the breakdown values
    expect(find.byType(TaskCrudModal), findsOneWidget);
    expect(find.text('Architect Crisp AMOLED Dark Theme System'), findsOneWidget);
  });
}
