import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/pages/home/wearable_home_page.dart';
import 'package:pin/pages/home/home_page.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/shared/ui/pin_breakpoints.dart';
import 'package:pin/widgets/kanban_board/layered_deck_view.dart';
import 'package:pin/widgets/kanban_board/wide_fold_kanban_view.dart';

void main() {
  group('PinBreakpoints unit tests', () {
    testWidgets('identifies xs tier when width < 320', (tester) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late PinScreenTier tier;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tier = PinBreakpoints.getTier(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tier, PinScreenTier.xs);
    });

    testWidgets('identifies small tier when 320 <= width < 720', (tester) async {
      tester.view.physicalSize = const Size(412, 892); // typical modern smartphone
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late PinScreenTier tier;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tier = PinBreakpoints.getTier(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tier, PinScreenTier.small);
      expect(PinBreakpoints.isSmall, isNotNull);
    });

    testWidgets('identifies wide tier when width >= 720', (tester) async {
      tester.view.physicalSize = const Size(768, 1024); // folded tablet / unfolded fold
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late PinScreenTier tier;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tier = PinBreakpoints.getTier(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tier, PinScreenTier.wide);
    });
  });

  group('HomePage Responsive Breakpoint Adaptability', () {
    Widget buildTestApp() {
      final fakeStorage = MemoryStorageAdapter();
      return ProviderScope(
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
      );
    }

    testWidgets('switches to WearableHomePage on xs viewports (< 320px)', (tester) async {
      tester.view.physicalSize = const Size(280, 280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(WearableHomePage), findsOneWidget);
      expect(find.byType(LayeredDeckView), findsNothing);
      expect(find.byType(WideFoldKanbanView), findsNothing);
    });

    testWidgets(
        'switches back to single drawer (LayeredDeckView) and full width on small viewports (smartphones & fold folded)',
        (tester) async {
      // 500px wide (e.g. wider smartphone or narrow web window)
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Must be single drawer
      expect(find.byType(LayeredDeckView), findsOneWidget);
      expect(find.byType(WideFoldKanbanView), findsNothing);

      // Verify full width container (render object width equals 500.0)
      final layeredDeckFinder = find.byType(LayeredDeckView);
      final renderBox = tester.renderObject<RenderBox>(layeredDeckFinder);
      expect(renderBox.size.width, 500.0);
    });

    testWidgets(
        'switches to 3-drawer layout (WideFoldKanbanView) on wide viewports (unfolded fold, desktop, wide web)',
        (tester) async {
      // 900px wide (unfolded fold or desktop/web)
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Must render 3-drawer view
      expect(find.byType(WideFoldKanbanView), findsOneWidget);
      expect(find.byType(LayeredDeckView), findsNothing);

      // Verify all 3 drawers exist simultaneously
      expect(find.text('To Do (Today)'), findsOneWidget);
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
