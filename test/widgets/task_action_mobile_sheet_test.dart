import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/widgets/kanban_board/components/task_action_mobile_sheet.dart';
import 'package:pin/widgets/kanban_board/task_action_bubble.dart';

void main() {
  final testTask = PinTask(
    id: 'task_mobile_test',
    title: 'Mobile responsiveness for pin actions',
    description: 'Ensure contextual action sheet works seamlessly on compact phones',
    status: TaskStatus.today,
    energyTag: 'quick-win',
    estimatedMinutes: 15,
    tags: ['#mobile', '#ui'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('TaskActionMobileSheet renders all 4 actions and handles taps', (tester) async {
    bool aiTapped = false;
    bool editTapped = false;
    bool shareTapped = false;
    bool deleteTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PinTheme.darkTheme,
        home: Scaffold(
          body: TaskActionMobileSheet(
            task: testTask,
            onAiBreakdown: () => aiTapped = true,
            onEdit: () => editTapped = true,
            onShare: () => shareTapped = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and all action titles/subtitles
    expect(find.text('Mobile responsiveness for pin actions'), findsOneWidget);
    expect(find.text('AI Breakdown'), findsOneWidget);
    expect(find.text('Re-analyze'), findsOneWidget);
    expect(find.text('Edit Pin'), findsOneWidget);
    expect(find.text('Full editor'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Text & Cal'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Remove pin'), findsOneWidget);

    // Tap actions
    await tester.tap(find.text('AI Breakdown'));
    await tester.pumpAndSettle();
    expect(aiTapped, isTrue);

    await tester.tap(find.text('Edit Pin'));
    await tester.pumpAndSettle();
    expect(editTapped, isTrue);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shareTapped, isTrue);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleteTapped, isTrue);
  });

  testWidgets('TaskActionBubble.show on compact smartphone viewport renders mobile sheet without overflow', (tester) async {
    // Smartphone viewport (390 x 844, typical iPhone / Pixel portrait)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PinTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TaskActionBubble.show(
                    context,
                    task: testTask,
                    targetPosition: const Offset(150, 400),
                  );
                },
                child: const Text('Open Menu'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap button to open menu
    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();

    // On mobile width (< 500), TaskActionMobileSheet should be rendered
    expect(find.byType(TaskActionMobileSheet), findsOneWidget);
    expect(find.text('Mobile responsiveness for pin actions'), findsOneWidget);
    expect(find.text('AI Breakdown'), findsOneWidget);
    expect(find.text('Edit Pin'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Verify close button dismisses sheet
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(TaskActionMobileSheet), findsNothing);
  });
}
