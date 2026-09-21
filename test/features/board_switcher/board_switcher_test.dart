import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/board_switcher/ui/board_selector_modal.dart';
import 'package:pin/features/board_switcher/ui/board_switcher_chip.dart';
import 'package:pin/features/board_switcher/ui/components/multi_board_pro_banner.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  group('Board Switcher UI Components', () {
    testWidgets('BoardSwitcherChip renders active board name and opens modal on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageAdapterProvider.overrideWithValue(MemoryStorageAdapter()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: BoardSwitcherChip(),
              ),
            ),
          ),
        ),
      );

      // Verify chip displays 'Personal' initially
      expect(find.text('Personal'), findsOneWidget);
      expect(find.byType(BoardSwitcherChip), findsOneWidget);

      // Tap chip to open BoardSelectorModal
      await tester.tap(find.byType(BoardSwitcherChip));
      await tester.pumpAndSettle();

      // Verify BoardSelectorModal opened with 1 board and Pro banner
      expect(find.byType(BoardSelectorModal), findsOneWidget);
      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.text('Personal'), findsWidgets);
      expect(find.byType(MultiBoardProBanner), findsOneWidget);
      expect(find.text('Multi-Board Workspaces'), findsOneWidget);
      expect(find.byTooltip('Create New Board'), findsOneWidget);
    });

    testWidgets('Tapping Create New Board when toggle disabled prompts to enable feature',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageAdapterProvider.overrideWithValue(MemoryStorageAdapter()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: BoardSwitcherChip(),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.byType(BoardSwitcherChip));
      await tester.pumpAndSettle();

      // Tap 'Create New Board' icon button while multi-board is off
      await tester.tap(find.byTooltip('Create New Board'));
      await tester.pumpAndSettle();

      // Verify Enable Multi-Board Workspaces prompt appears
      expect(find.text('Enable & Create'), findsOneWidget);

      // Tap 'Enable & Create'
      await tester.tap(find.text('Enable & Create'));
      await tester.pumpAndSettle();

      // Create Board dialog should appear
      expect(find.text('Create Board'), findsOneWidget);

      // Enter board title
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Projects');
      await tester.pump();

      // Tap Create button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // The active board should now be 'Projects'
      expect(find.text('Projects'), findsWidgets);
    });

    testWidgets('Toggling MultiBoardProBanner switch directly enables multi-board capability',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageAdapterProvider.overrideWithValue(MemoryStorageAdapter()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: BoardSwitcherChip(),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.byType(BoardSwitcherChip));
      await tester.pumpAndSettle();

      // Locate switch in MultiBoardProBanner
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap switch to turn on multi-board
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Tap Create New Board (should open Create Board dialog directly now)
      await tester.tap(find.byTooltip('Create New Board'));
      await tester.pumpAndSettle();

      expect(find.text('Create Board'), findsOneWidget);
      expect(find.text('Enable & Create'), findsNothing);
    });
  });
}
