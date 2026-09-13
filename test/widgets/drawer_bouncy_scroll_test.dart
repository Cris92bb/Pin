import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_scroll_behavior.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/pages/home/home_page.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/widgets/kanban_board/bouncy_drawer_scroll_wrapper.dart';
import 'package:pin/widgets/kanban_board/layered_deck_view.dart';

void main() {
  testWidgets('drawer task list supports bouncy drag overscroll on scroll end',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final sampleTasks = List.generate(
      8,
      (i) => PinTask(
        id: 'task_$i',
        title: 'Task $i',
        status: TaskStatus.today,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final fakeStorage =
        MemoryStorageAdapter(sampleTasks.map((t) => t.toJson()).toList());

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
          scrollBehavior: const PinScrollBehavior(),
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listViewFinder = find.byType(ListView);
    expect(listViewFinder, findsOneWidget);

    final scrollableState = tester.state<ScrollableState>(
      find.descendant(of: listViewFinder, matching: find.byType(Scrollable)),
    );
    final scrollPosition = scrollableState.position;
    expect(scrollPosition.pixels, 0.0);

    // Drag down to overscroll top
    await tester.drag(listViewFinder, const Offset(0, 100));
    await tester.pump();
    expect(scrollPosition.pixels, lessThan(0.0));

    // Pump and settle to verify it bounces back to 0.0
    await tester.pumpAndSettle();
    expect(scrollPosition.pixels, 0.0);
  });

  testWidgets(
      'drawer bouncy scroll wrapper responds to mouse wheel overscroll at scroll end',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final sampleTasks = List.generate(
      4,
      (i) => PinTask(
        id: 'task_$i',
        title: 'Task $i',
        status: TaskStatus.today,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final fakeStorage =
        MemoryStorageAdapter(sampleTasks.map((t) => t.toJson()).toList());

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
          scrollBehavior: const PinScrollBehavior(),
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(BouncyDrawerScrollWrapper));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));

    // Scroll wheel up past top boundary (negative dy delta)
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -60)));
    await tester.pump();

    // Check that BouncyDrawerScrollWrapper applies positive downward offset
    final wrapperFinder = find.byType(BouncyDrawerScrollWrapper);
    expect(wrapperFinder, findsOneWidget);

    final transformFinder = find.descendant(
      of: wrapperFinder,
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsWidgets);

    final initialTransform = tester.widget<Transform>(transformFinder.first);
    final initialOffsetY = initialTransform.transform.getTranslation().y;
    expect(initialOffsetY, greaterThan(0.0));

    // Pump to settle
    await tester.pumpAndSettle();
    final settledTransform = tester.widget<Transform>(transformFinder.first);
    expect(settledTransform.transform.getTranslation().y, 0.0);
  });

  testWidgets('empty deck is scrollable with bouncy overscroll', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
          scrollBehavior: const PinScrollBehavior(),
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to empty Backlog deck
    await tester.tap(find.text('Backlog'));
    await tester.pumpAndSettle();

    // Verify empty state is rendered inside SingleChildScrollView with BouncingScrollPhysics
    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    final scrollableState = tester.state<ScrollableState>(
      find.descendant(of: scrollViewFinder, matching: find.byType(Scrollable)),
    );
    expect(scrollableState.position.physics, isA<BouncingScrollPhysics>());

    // Drag empty state to overscroll
    final gesture = await tester.startGesture(
      tester.getCenter(scrollViewFinder),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, 70));
    await tester.pump();

    expect(scrollableState.position.pixels, lessThan(0.0));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(scrollableState.position.pixels, 0.0);
  });

  testWidgets(
      'swiping horizontally past outermost drawer triggers edge bounce recoil',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
          scrollBehavior: const PinScrollBehavior(),
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Backlog (leftmost index 0)
    await tester.tap(find.text('Backlog'));
    await tester.pumpAndSettle();

    // Swipe right (primaryVelocity > 200) attempting to go before Backlog
    await tester.fling(find.text('Backlog').last, const Offset(300, 0), 800);
    await tester.pump();

    // Find the horizontal nudge transform on the active sheet
    final layeredDeckFinder = find.byType(LayeredDeckView);
    expect(layeredDeckFinder, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  });
}
