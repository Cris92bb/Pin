import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/sync/ui/firebase_account_modal.dart';
import 'package:pin/features/sync/ui/sync_status_badge.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';

void main() {
  group('Sync UI Widgets', () {
    testWidgets('renders SyncStatusBadge and opens FirebaseAccountModal on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageAdapterProvider.overrideWithValue(MemoryStorageAdapter()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SyncStatusBadge(),
              ),
            ),
          ),
        ),
      );

      // Verify SyncStatusBadge is rendered with cloud icon
      expect(find.byType(SyncStatusBadge), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);

      // Tap badge to open modal
      await tester.tap(find.byType(SyncStatusBadge));
      await tester.pumpAndSettle();

      // Verify FirebaseAccountModal is open
      expect(find.byType(FirebaseAccountModal), findsOneWidget);
      expect(find.text('Cloud Sync & Account'), findsOneWidget);
      expect(find.text('Offline-First (Guest Mode)'), findsOneWidget);
      expect(find.text('Firebase Project Settings'), findsOneWidget);

      // Expand Firebase Project Settings
      await tester.tap(find.text('Firebase Project Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Firebase API Key'), findsOneWidget);
      expect(find.text('Project ID'), findsOneWidget);
    });
  });
}
