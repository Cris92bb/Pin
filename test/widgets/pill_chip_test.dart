import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/shared/ui/pill_chip.dart';
import 'package:pin/shared/ui/pin_tokens.dart';

void main() {
  group('PillChip Theme Awareness', () {
    testWidgets('renders light theme unselected pill with crisp light background and slate text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PinTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: PillChip.duration(
                durationText: '~15m',
                isSelected: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('~15m'));
      expect(textWidget.style?.color, const Color(0xFF374151));

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFF3F4F6));
      expect(decoration.border?.top.color, const Color(0xFFE5E7EB));
    });

    testWidgets('renders light theme selected energy pill with vibrant accent and tint',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PinTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: PillChip.energy(
                tag: 'low-friction',
                isSelected: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('low-friction'));
      // High contrast emerald text
      expect(textWidget.style?.color, const Color(0xFF047857));

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, const Color(0xFF10B981));
    });

    testWidgets('renders dark theme unselected pill with obsidian background and slate text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: PillChip.duration(
                durationText: '~30m',
                isSelected: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('~30m'));
      expect(textWidget.style?.color, PinTokens.darkTextSecondary);

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, PinTokens.darkCardBg);
      expect(decoration.border?.top.color, PinTokens.darkBorder);
    });
  });
}
