import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/features/task_export_import/ui/single_task_share_modal.dart';

void main() {
  final sampleTask = PinTask(
    id: 'share_task_1',
    title: 'Deploy microservice to staging',
    description: 'Ensure environment variables and healthchecks pass',
    status: TaskStatus.today,
    energyTag: 'deep-focus',
    estimatedMinutes: 25,
    tags: ['#deploy', '#cloud'],
    subtasks: const [
      AtomicStep(id: 's1', title: 'Verify credentials', isCompleted: true),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('SingleTaskShareModal renders all three tabs and switches smoothly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PinTheme.darkTheme,
        home: Scaffold(
          body: SingleTaskShareModal(task: sampleTask),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Tabs
    expect(find.text('Share Pin: Deploy microservice to staging'), findsOneWidget);
    expect(find.text('As Text'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Blueprint'), findsOneWidget);

    // Initial tab: As Text
    expect(find.text('Copy Formatted Text'), findsOneWidget);
    expect(find.textContaining('📌 Deploy microservice to staging'), findsOneWidget);

    // Switch to Calendar tab
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Open in Calendar'), findsOneWidget);
    expect(find.text('Copy .ics'), findsOneWidget);

    // Switch to Blueprint tab
    await tester.tap(find.text('Blueprint'));
    await tester.pumpAndSettle();
    expect(find.text('Copy Blueprint Code'), findsOneWidget);
    expect(find.textContaining('PIN_BP_'), findsOneWidget);
  });
}
