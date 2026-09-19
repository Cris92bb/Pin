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
      expect(textWidget.style?.color, PinTokens.lightTextSecondary);

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, PinTokens.lightTagBg);
      expect(decoration.border?.top.color, PinTokens.lightBorder);
    });

    testWidgets('renders light theme selected energy pill with harmonic accent and tint',
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
      // Harmonic deep forest text
      expect(textWidget.style?.color, PinTokens.energyLowText);

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, const Color(0xFFA7D7BE));
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

    testWidgets('renders dark theme selected energy pill with adjusted dark accents',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PinTheme.darkTheme,
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
      expect(textWidget.style?.color, PinTokens.darkEnergyLowText);

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, PinTokens.darkEnergyLowBg);
      expect(decoration.border?.top.color, PinTokens.darkEnergyLowText);
    });

    testWidgets('renders dark theme selected duration pill with indigo/lavender accents',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: PillChip.duration(
                durationText: '~15m',
                isSelected: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('~15m'));
      expect(textWidget.style?.color, PinTokens.darkTimerText);

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, PinTokens.darkTimerBg);
      expect(decoration.border?.top.color, PinTokens.darkTimerText);
    });
  });
}
