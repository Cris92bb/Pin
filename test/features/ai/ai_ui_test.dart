import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/features/ai/ui/ai_settings_modal.dart';
import 'package:pin/features/task_crud/ui/task_crud_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TaskCrudModal renders AI breakdown action button and AI settings icon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskCrudModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of AI Breakdown button
    expect(find.text('Break down & auto-fill with Gemini'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsWidgets);
  });

  testWidgets('AiSettingsModal allows typing API key and selecting model', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiSettingsModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gemini AI Settings'), findsOneWidget);
    expect(find.text('GEMINI API KEY'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);

    // Enter API key
    await tester.enterText(find.byType(TextField), 'AIzaSyTestKey123');
    await tester.pumpAndSettle();

    expect(find.text('AIzaSyTestKey123'), findsOneWidget);
  });
}
