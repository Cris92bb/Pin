import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/task_export_import/ui/task_export_import_modal.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  testWidgets('TaskExportImportModal renders tabs and sub-selectors properly', (tester) async {
    final fakeStorage = MemoryStorageAdapter();
    final notifier = TaskStateNotifier(storage: fakeStorage, seedInitialSample: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: const Scaffold(
            body: TaskExportImportModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and primary tabs
    expect(find.text('Transfer & Share Pins'), findsOneWidget);
    expect(find.text('Share & Export'), findsOneWidget);
    expect(find.text('Import Pins'), findsOneWidget);

    // Export sub-selectors
    expect(find.text('Text Note'), findsOneWidget);
    expect(find.text('Calendar Event'), findsOneWidget);
    expect(find.text('Portable Blueprint'), findsOneWidget);

    // Default view: Text Note
    expect(find.text('Copy Formatted Text'), findsOneWidget);

    // Switch to Calendar Event sub-selector
    await tester.tap(find.text('Calendar Event'));
    await tester.pumpAndSettle();
    expect(find.text('Add to Calendar'), findsOneWidget);
    expect(find.text('Copy .ics Data'), findsOneWidget);

    // Switch to Portable Blueprint sub-selector
    await tester.tap(find.text('Portable Blueprint'));
    await tester.pumpAndSettle();
    expect(find.text('Copy Blueprint Code'), findsOneWidget);

    // Switch to primary tab: Import Pins
    await tester.tap(find.text('Import Pins'));
    await tester.pumpAndSettle();

    expect(find.text('From Blueprint / JSON'), findsOneWidget);
    expect(find.text('From Text / Checklist'), findsOneWidget);
    expect(find.text('Paste Blueprint Code or JSON:'), findsOneWidget);

    // Switch to From Text / Checklist
    await tester.tap(find.text('From Text / Checklist'));
    await tester.pumpAndSettle();
    expect(find.text('Paste Notes or Checklist:'), findsOneWidget);
  });
}
