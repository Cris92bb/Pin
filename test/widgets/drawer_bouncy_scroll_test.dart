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

void main() {
  testWidgets(
      'drawer task list provides tight bouncy drag overscroll capped to prevent long empty space',
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
            () => TaskStateNotifier(
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

    // Pull down to overscroll top
    await tester.drag(listViewFinder, const Offset(0, 100));
    await tester.pump();

    // Verify overscroll is tight and capped to prevent large empty void
    final transformFinder = find.descendant(
      of: find.byType(BouncyDrawerScrollWrapper),
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsWidgets);

    final transform = tester.widget<Transform>(transformFinder.first);
    final offsetY = transform.transform.getTranslation().y;
    expect(offsetY, greaterThan(0.0));
    expect(offsetY, lessThanOrEqualTo(10.0));

    // Settle back to 0.0
    await tester.pumpAndSettle();
    final settled = tester.widget<Transform>(transformFinder.first);
    expect(settled.transform.getTranslation().y, 0.0);
  });

  testWidgets(
      'drawer bouncy scroll wrapper provides tight mouse wheel bounce (<= 10px) at scroll end',
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
            () => TaskStateNotifier(
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

    // Check that BouncyDrawerScrollWrapper applies tight downward offset (<= 10px)
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
    expect(initialOffsetY, lessThanOrEqualTo(10.0));

    // Pump to settle
    await tester.pumpAndSettle();
    final settledTransform = tester.widget<Transform>(transformFinder.first);
    expect(settledTransform.transform.getTranslation().y, 0.0);
  });

  testWidgets('empty deck is scrollable with tight bouncy overscroll',
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
            () => TaskStateNotifier(
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

    // Verify empty state is rendered inside SingleChildScrollView with ClampingScrollPhysics
    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    final scrollableState = tester.state<ScrollableState>(
      find.descendant(of: scrollViewFinder, matching: find.byType(Scrollable)),
    );
    expect(scrollableState.position.physics, isA<ClampingScrollPhysics>());

    // Drag empty state to overscroll
    await tester.drag(scrollViewFinder, const Offset(0, 70));
    await tester.pump();

    final transformFinder = find.descendant(
      of: find.byType(BouncyDrawerScrollWrapper),
      matching: find.byType(Transform),
    );
    final transform = tester.widget<Transform>(transformFinder.first);
    expect(transform.transform.getTranslation().y, greaterThan(0.0));
    expect(transform.transform.getTranslation().y, lessThanOrEqualTo(10.0));

    await tester.pumpAndSettle();
    final settled = tester.widget<Transform>(transformFinder.first);
    expect(settled.transform.getTranslation().y, 0.0);
  });

  testWidgets(
      'swiping horizontally past outermost drawer triggers tight edge bounce recoil',
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
            () => TaskStateNotifier(
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

    // Swipe right attempting to go before Backlog
    await tester.fling(find.text('Backlog').last, const Offset(300, 0), 800);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'PinScrollBehavior supplies TightBouncingScrollPhysics capping overscroll <= 10px across all views',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    const behavior = PinScrollBehavior();
    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final physics = behavior.getScrollPhysics(context);
    expect(physics, isA<TightBouncingScrollPhysics>());
    final tightPhysics = physics as TightBouncingScrollPhysics;
    expect(tightPhysics.maxOverscroll, equals(10.0));
  });
}
