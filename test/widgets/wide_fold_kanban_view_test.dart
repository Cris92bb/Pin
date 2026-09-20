import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/focus_mode/ui/focus_mode_view.dart';
import 'package:pin/features/task_crud/ui/task_crud_modal.dart';
import 'package:pin/pages/home/home_page.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/shared/ui/pin_tokens.dart';
import 'package:pin/widgets/kanban_board/components/wide_fold_docking_tray.dart';
import 'package:pin/widgets/kanban_board/task_card.dart';
import 'package:pin/widgets/kanban_board/wide_fold_kanban_view.dart';

void main() {
  testWidgets('renders WideFoldKanbanView with 3 drawers side-by-side on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

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
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify WideFoldKanbanView is active on wide screen
    expect(find.byType(WideFoldKanbanView), findsOneWidget);

    // Verify all 3 drawers exist simultaneously
    expect(find.text('To Do (Today)'), findsOneWidget);
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('tapping an inactive drawer switches places with active drawer',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();
    late WidgetRef capturedRef;

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
          theme: PinTheme.lightTheme,
          home: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const HomePage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially active deck is Today
    expect(capturedRef.read(activeDeckProvider), TaskStatus.today);

    // Tap Done drawer to switch places
    final doneDrawer = find.text('Done');
    expect(doneDrawer, findsOneWidget);
    await tester.tap(doneDrawer);
    await tester.pumpAndSettle();

    // Done is now the active drawer!
    expect(capturedRef.read(activeDeckProvider), TaskStatus.done);

    // Tap Backlog drawer to switch places
    final backlogDrawer = find.text('Backlog');
    expect(backlogDrawer, findsOneWidget);
    await tester.tap(backlogDrawer);
    await tester.pumpAndSettle();

    // Backlog is now the active drawer!
    expect(capturedRef.read(activeDeckProvider), TaskStatus.backlog);
  });

  testWidgets('clicking a task card overlays FocusModeView on top of inactive drawers',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final sampleTask = PinTask(
      id: 'task_wide_focus',
      title: 'Wide Screen Focus Task',
      description: 'Testing the fold & web layout overlay',
      status: TaskStatus.today,
      isPinned: true,
      energyTag: 'deep-focus',
      estimatedMinutes: 25,
      tags: const ['#web'],
      createdAt: now,
      updatedAt: now,
    );
    final fakeStorage = MemoryStorageAdapter([sampleTask.toJson()]);

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
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the task card
    final card = find.byType(TaskCard);
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Verify FocusModeView is now present in the overlay
    expect(find.byType(FocusModeView), findsOneWidget);
    expect(find.text('Wide Screen Focus Task'), findsAtLeastNWidgets(1));

    // Active drawer title is still visible beside the focus overlay!
    expect(find.text('To Do (Today)'), findsOneWidget);

    // Click back to exit Focus Mode
    final backBtn = find.byTooltip('Return to Board (Esc)');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // FocusModeView dismissed, revealing inactive drawers again
    expect(find.byType(FocusModeView), findsNothing);
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('triggering task creation overlays TaskCrudModal inline on top of inactive drawers',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

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
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Click "+" button in active drawer header
    final addIcon = find.byTooltip('Capture Pin in To Do (Today)');
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // TaskCrudModal is rendered inline as an overlay
    expect(find.byType(TaskCrudModal), findsOneWidget);
    expect(find.text('Capture New Pin'), findsOneWidget);

    // Click Cancel to dismiss
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // TaskCrudModal dismissed
    expect(find.byType(TaskCrudModal), findsNothing);
  });

  testWidgets(
      'when in focus mode, clicking any pin on active drawer selects that one as focused',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final task1 = PinTask(
      id: 'task_1',
      title: 'First Focused Task',
      description: 'First task details',
      status: TaskStatus.today,
      isPinned: true,
      energyTag: 'deep-focus',
      estimatedMinutes: 25,
      tags: const ['#one'],
      createdAt: now,
      updatedAt: now,
    );
    final task2 = PinTask(
      id: 'task_2',
      title: 'Second Focused Task',
      description: 'Second task details',
      status: TaskStatus.today,
      isPinned: true,
      energyTag: 'creative',
      estimatedMinutes: 30,
      tags: const ['#two'],
      createdAt: now.add(const Duration(seconds: 1)),
      updatedAt: now.add(const Duration(seconds: 1)),
    );
    final fakeStorage = MemoryStorageAdapter([task1.toJson(), task2.toJson()]);

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
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Click Task 1 to focus it
    await tester.tap(find.text('First Focused Task'));
    await tester.pumpAndSettle();

    // FocusModeView is open with First Focused Task
    expect(find.byType(FocusModeView), findsOneWidget);
    expect(find.text('First Focused Task'), findsAtLeastNWidgets(1));

    // Now click Task 2 in the active drawer
    await tester.tap(find.text('Second Focused Task'));
    await tester.pumpAndSettle();

    // FocusModeView now switches to Second Focused Task!
    expect(find.byType(FocusModeView), findsOneWidget);
    expect(find.text('Second Focused Task'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'editing a pin goes on top of focus mode with at max 1 overlay at a time, resuming focus on cancel',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final task = PinTask(
      id: 'task_edit_layering',
      title: 'Task To Edit On Top',
      description: 'Testing overlay priority',
      status: TaskStatus.today,
      isPinned: true,
      energyTag: 'deep-focus',
      estimatedMinutes: 25,
      tags: const ['#overlay'],
      createdAt: now,
      updatedAt: now,
    );
    final fakeStorage = MemoryStorageAdapter([task.toJson()]);

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
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Click task to enter focus mode
    await tester.tap(find.text('Task To Edit On Top'));
    await tester.pumpAndSettle();

    expect(find.byType(FocusModeView), findsOneWidget);
    expect(find.byType(TaskCrudModal), findsNothing);

    // Click "Edit" in FocusModeView
    final editBtn = find.byTooltip('Edit Pin');
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    // TaskCrudModal is now ON TOP as the single overlay instance
    expect(find.byType(TaskCrudModal), findsOneWidget);
    expect(find.byType(FocusModeView), findsNothing); // only 1 overlay rendered at a time

    // Cancel editing
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // Editor dismissed, FocusModeView returns!
    expect(find.byType(TaskCrudModal), findsNothing);
    expect(find.byType(FocusModeView), findsOneWidget);
  });

  testWidgets(
      'wide UI renders without outer window border and clips inactive drawer tasks with foregroundDecoration',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: true,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify outer container has no borders around the app
    final homeScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(homeScaffold.backgroundColor, equals(PinTokens.darkPhoneFrameBg));

    // 2. Find drawers and verify clipBehavior and foregroundDecoration
    final containers = tester.widgetList<Container>(find.byType(Container));
    final clippedDeckContainers = containers.where((c) =>
        c.clipBehavior == Clip.antiAlias &&
        c.foregroundDecoration is BoxDecoration &&
        (c.foregroundDecoration as BoxDecoration).border != null);

    // Active drawer + inactive drawers all have antiAlias clip & foregroundDecoration border
    expect(clippedDeckContainers.length, greaterThanOrEqualTo(3));
  });

  testWidgets(
      'tapping an inactive drawer mounts docking tray and smoothly glides during animation',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

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
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In idle state, docking tray is not present
    expect(find.byType(WideFoldDockingTray), findsNothing);

    // Tap Done drawer
    final doneDrawer = find.text('Done');
    expect(doneDrawer, findsOneWidget);
    await tester.tap(doneDrawer);

    // Advance animation midway
    await tester.pump(const Duration(milliseconds: 150));

    // Docking tray is now visible in the vacated slot!
    expect(find.byType(WideFoldDockingTray), findsOneWidget);

    // Complete transition
    await tester.pumpAndSettle();

    // Docking tray is gone, Done is docked in active column
    expect(find.byType(WideFoldDockingTray), findsNothing);
  });
}

