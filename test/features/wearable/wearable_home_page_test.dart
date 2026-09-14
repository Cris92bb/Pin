import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/pages/home/home_page.dart';
import 'package:pin/pages/home/wearable_home_page.dart';
import 'package:pin/shared/ui/wearable_utils.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  group('WearableUtils', () {
    testWidgets('accurately identifies wearable vs phone/desktop viewports',
        (tester) async {
      // Test watch screen dimension (240x240)
      tester.view.physicalSize = const Size(240, 240);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? isWatch;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isWatch = WearableUtils.isWearable(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(isWatch, isTrue);

      // Test phone viewport (412x915)
      tester.view.physicalSize = const Size(412, 915);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isWatch = WearableUtils.isWearable(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(isWatch, isFalse);
    });
  });

  group('WearableHomePage', () {
    testWidgets('HomePage adapts to WearableHomePage and allows quick focus',
        (tester) async {
      // Set smartwatch circular viewport (300x300)
      tester.view.physicalSize = const Size(300, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final task1 = PinTask(
        id: 'watch_task_1',
        title: 'Review Wear OS Spec',
        description: 'Ensure watch UI fits edge margins',
        status: TaskStatus.today,
        energyTag: 'deep-focus',
        estimatedMinutes: 20,
        trackedSeconds: 0,
        subtasks: const [
          AtomicStep(id: 's1', title: 'Check OLED contrast', isCompleted: false),
          AtomicStep(id: 's2', title: 'Verify circular padding', isCompleted: false),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final task2 = PinTask(
        id: 'watch_task_2',
        title: 'Backlog Standby Pin',
        description: 'Queued item in backlog',
        status: TaskStatus.backlog,
        energyTag: 'low-friction',
        estimatedMinutes: 10,
        trackedSeconds: 0,
        createdAt: now,
        updatedAt: now,
      );

      final fakeStorage = MemoryStorageAdapter([task1.toJson(), task2.toJson()]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageAdapterProvider.overrideWithValue(fakeStorage),
          ],
          child: MaterialApp(
            theme: PinTheme.darkTheme,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that WearableHomePage rendered because of watch viewport
      expect(find.byType(WearableHomePage), findsOneWidget);
      expect(find.text('TODAY 1/5'), findsOneWidget);
      expect(find.text('Review Wear OS Spec'), findsOneWidget);
      // Verify description is rendered on the watch card
      expect(find.text('Ensure watch UI fits edge margins'), findsOneWidget);
      expect(find.text('0/2 steps completed'), findsOneWidget);
      expect(find.text('START FOCUS'), findsOneWidget);

      // Verify title is configured for 2 lines and description for 3 lines
      final titleWidget = tester.widget<Text>(find.text('Review Wear OS Spec'));
      expect(titleWidget.maxLines, 2);
      final descWidget =
          tester.widget<Text>(find.text('Ensure watch UI fits edge margins'));
      expect(descWidget.maxLines, 3);

      // Tap START FOCUS to enter WearableFocusView
      await tester.tap(find.text('START FOCUS'));
      await tester.pumpAndSettle();

      expect(find.byType(WearableFocusView), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Ensure watch UI fits edge margins'), findsOneWidget);
      expect(find.text('STEPS (0/2)'), findsOneWidget);

      // Toggle first subtask in watch focus view
      await tester.tap(find.text('Check OLED contrast'));
      await tester.pumpAndSettle();
      expect(find.text('STEPS (1/2)'), findsOneWidget);

      // Test Android back navigation within WearableFocusView
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      final didPop = await widgetsAppState.didPopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      // Should return to WearableHomePage today view
      expect(find.byType(WearableHomePage), findsOneWidget);
      expect(find.text('TODAY 1/5'), findsOneWidget);

      // Swipe left to advance to Backlog page
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pumpAndSettle();

      expect(find.text('BACKLOG (1)'), findsOneWidget);
      expect(find.text('Backlog Standby Pin'), findsOneWidget);
      expect(find.text('Queued item in backlog'), findsOneWidget);

      // Move task from Backlog to Today
      await tester.tap(find.byTooltip('Move to Today'));
      await tester.pumpAndSettle();

      // Verify that dragging to the right (swiping backwards) is BLOCKED
      await tester.drag(find.byType(PageView), const Offset(250, 0));
      await tester.pumpAndSettle();
      // Should still be on Backlog, NOT Today
      expect(find.text('BACKLOG (0)'), findsOneWidget);
      expect(find.text('TODAY 2/5'), findsNothing);

      // Swipe left to advance to Done page
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(find.text('COMPLETED (0)'), findsOneWidget);

      // Swipe left to advance to Account page
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(find.text('ACCOUNT (GUEST)'), findsOneWidget);
      expect(find.text('GOOGLE SIGN-IN'), findsOneWidget);
      expect(find.text('EMAIL SIGN-IN'), findsOneWidget);

      // Tap GOOGLE SIGN-IN to verify watch login dialog renders
      await tester.tap(find.text('GOOGLE SIGN-IN'));
      await tester.pumpAndSettle();
      expect(find.text('Google Sign-In'), findsOneWidget);
      expect(find.text('Sign in on your paired phone to automatically sync your pins.'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Swipe left to loop back around to Today page
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(find.text('TODAY 2/5'), findsOneWidget);
    });

    testWidgets('LeftOnlyPageScrollPhysics strictly restricts movement',
        (tester) async {
      const physics = LeftOnlyPageScrollPhysics();

      final fakeMetrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: 400,
        viewportDimension: 300,
        axisDirection: AxisDirection.right,
        devicePixelRatio: 1.0,
      );

      // Dragging right (swiping backwards) gives offset > 0 -> should be 0
      expect(physics.applyPhysicsToUserOffset(fakeMetrics, 20.0), 0.0);

      // Dragging left (swiping forwards) gives offset < 0 -> should be passed through
      expect(physics.applyPhysicsToUserOffset(fakeMetrics, -20.0), -20.0);

      // Scrolling towards lower pixels (backward) should be blocked by boundary condition
      expect(physics.applyBoundaryConditions(fakeMetrics, 380.0), 380.0 - 400.0);

      // Scrolling forwards should have zero boundary condition
      expect(physics.applyBoundaryConditions(fakeMetrics, 420.0), 0.0);
    });
  });
}

