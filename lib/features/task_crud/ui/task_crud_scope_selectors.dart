import 'package:flutter/material.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../shared/ui/pill_chip.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Selectors for time estimation and energy states in TaskCrudModal.
class TaskCrudScopeSelectors extends StatelessWidget {
  /// Selected duration in minutes.
  final int selectedEstimateMinutes;

  /// Selected energy tag string.
  final String selectedEnergyTag;

  /// Callback when duration is changed.
  final ValueChanged<int> onEstimateChanged;

  /// Callback when energy tag is changed.
  final ValueChanged<String> onEnergyChanged;

  static const List<int> _estimationOptions = [5, 15, 30, 45, 60, 120];
  static const List<String> _energyTags = [
    'low-friction',
    'medium-flow',
    'deep-focus',
    'creative',
    'administrative',
  ];

  /// Creates a [TaskCrudScopeSelectors].
  const TaskCrudScopeSelectors({
    super.key,
    required this.selectedEstimateMinutes,
    required this.selectedEnergyTag,
    required this.onEstimateChanged,
    required this.onEnergyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Scope Estimate',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _estimationOptions.map((minutes) {
            final label = DateHelpers.formatMinutes(minutes);
            final isSelected = selectedEstimateMinutes == minutes;
            return PillChip.duration(
              durationText: label,
              isSelected: isSelected,
              onTap: () => onEstimateChanged(minutes),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Energy State',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _energyTags.map((tag) {
            final isSelected = selectedEnergyTag == tag;
            return PillChip.energy(
              tag: tag,
              isSelected: isSelected,
              onTap: () => onEnergyChanged(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}
