import 'package:flutter/material.dart';
import 'pin_tokens.dart';

/// Reusable pill chip used for duration estimates (`~15m`) and energy tags.
///
/// Features clean, theme-aware styling:
/// - Light Mode: Crisp off-white/subtle gray background with light slate border,
///   colored accent icons, and rich high-contrast text. Selected state glows with
///   a soft tinted fill and crisp saturated border.
/// - Dark Mode: Sleek obsidian background with slate border and luminous accents.
class PillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;

  const PillChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
  });

  /// Specialized constructor for Energy Tag chips
  factory PillChip.energy({
    Key? key,
    required String tag,
    bool isSelected = false,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    final color = PinTokens.energyTagColors[tag] ?? PinTokens.accentSky;
    IconData icon;
    switch (tag) {
      case 'deep-focus':
        icon = Icons.bolt_rounded;
        break;
      case 'low-friction':
        icon = Icons.spa_rounded;
        break;
      case 'medium-flow':
        icon = Icons.waves_rounded;
        break;
      case 'creative':
        icon = Icons.auto_awesome_rounded;
        break;
      case 'administrative':
        icon = Icons.inventory_2_outlined;
        break;
      default:
        icon = Icons.label_outline_rounded;
    }

    return PillChip(
      key: key,
      label: tag,
      icon: icon,
      color: color,
      isSelected: isSelected,
      onTap: onTap,
      isCompact: isCompact,
    );
  }

  /// Specialized constructor for Duration Estimation chips
  factory PillChip.duration({
    Key? key,
    required String durationText,
    bool isSelected = false,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    return PillChip(
      key: key,
      label: durationText,
      icon: Icons.timer_outlined,
      color: PinTokens.lightTextSecondary,
      isSelected: isSelected,
      onTap: onTap,
      isCompact: isCompact,
    );
  }

  static Color _getLightText(Color accent) {
    if (accent == PinTokens.lightFabBg || accent == PinTokens.lightTextSecondary) {
      return PinTokens.lightFabBg;
    }
    if (accent == PinTokens.accentEmerald) return PinTokens.energyLowAccentText;
    if (accent == PinTokens.accentAmber) return PinTokens.energyMediumAccentText;
    if (accent == PinTokens.accentViolet) return PinTokens.energyDeepAccentText;
    if (accent == PinTokens.accentSky ||
        accent == PinTokens.energyMediumFlow ||
        accent == PinTokens.energyAdministrative) {
      return PinTokens.energySkyAccentText;
    }
    if (accent == PinTokens.energyBlue) return PinTokens.energyBlueAccentText;
    return accent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseAccent = color ??
        (isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus);

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;

    final isDuration = icon == Icons.timer_outlined;

    if (isSelected) {
      if (isDark) {
        if (isDuration) {
          bgColor = PinTokens.darkTimerBg;
          borderColor = PinTokens.darkTimerText;
          textColor = PinTokens.darkTimerText;
          iconColor = PinTokens.darkTimerText;
        } else {
          switch (label) {
            case 'low-friction':
              bgColor = PinTokens.darkEnergyLowBg;
              borderColor = PinTokens.darkEnergyLowText;
              textColor = PinTokens.darkEnergyLowText;
              iconColor = PinTokens.darkEnergyLowText;
              break;
            case 'medium-flow':
              bgColor = PinTokens.darkEnergyMediumBg;
              borderColor = PinTokens.darkEnergyMediumText;
              textColor = PinTokens.darkEnergyMediumText;
              iconColor = PinTokens.darkEnergyMediumText;
              break;
            case 'deep-focus':
              bgColor = PinTokens.darkEnergyFocusBg;
              borderColor = PinTokens.darkEnergyFocusText;
              textColor = PinTokens.darkEnergyFocusText;
              iconColor = PinTokens.darkEnergyFocusText;
              break;
            default:
              bgColor = baseAccent.withValues(alpha: 0.22);
              borderColor = baseAccent;
              textColor = baseAccent;
              iconColor = baseAccent;
          }
        }
      } else {
        if (isDuration) {
          bgColor = PinTokens.lightSheetBg;
          borderColor = PinTokens.lightFabBg;
          textColor = PinTokens.lightTextPrimary;
          iconColor = PinTokens.lightFabBg;
        } else {
          switch (label) {
            case 'low-friction':
              bgColor = PinTokens.energyLowBg;
              borderColor = PinTokens.energyLowBorder;
              textColor = PinTokens.energyLowText;
              iconColor = PinTokens.energyLowText;
              break;
            case 'medium-flow':
              bgColor = PinTokens.energyMediumBg;
              borderColor = PinTokens.energyMediumBorder;
              textColor = PinTokens.energyMediumText;
              iconColor = PinTokens.energyMediumText;
              break;
            case 'deep-focus':
              bgColor = PinTokens.energyDeepBg;
              borderColor = PinTokens.energyDeepBorder;
              textColor = PinTokens.energyDeepText;
              iconColor = PinTokens.energyDeepText;
              break;
            case 'creative':
              bgColor = PinTokens.energyCreativeBg;
              borderColor = PinTokens.energyCreativeBorder;
              textColor = PinTokens.energyCreativeText;
              iconColor = PinTokens.energyCreativeText;
              break;
            case 'administrative':
              bgColor = PinTokens.energyAdminBg;
              borderColor = PinTokens.energyAdminBorder;
              textColor = PinTokens.energyAdminText;
              iconColor = PinTokens.energyAdminText;
              break;
            default:
              bgColor = baseAccent.withValues(alpha: 0.12);
              borderColor = baseAccent;
              textColor = _getLightText(baseAccent);
              iconColor = _getLightText(baseAccent);
          }
        }
      }
    } else {
      if (isDark) {
        bgColor = PinTokens.darkCardBg;
        borderColor = PinTokens.darkBorder;
        textColor = PinTokens.darkTextSecondary;
        iconColor = isDuration ? PinTokens.darkTextTertiary : baseAccent.withValues(alpha: 0.7);
      } else {
        bgColor = PinTokens.lightTagBg;
        borderColor = PinTokens.lightBorder;
        textColor = PinTokens.lightTextSecondary;
        iconColor = PinTokens.lightTextTertiary;
      }
    }

    final verticalPadding = isCompact ? 3.0 : 6.0;
    final horizontalPadding = isCompact ? 8.0 : 12.0;
    final fontSize = isCompact ? 11.0 : 12.0;
    final iconSize = isCompact ? 13.0 : 15.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: iconColor),
          SizedBox(width: isCompact ? 4 : 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    return AnimatedContainer(
      duration: PinTokens.animFast,
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: PinTokens.radiusFull,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.2 : 1.0,
        ),
        boxShadow: isSelected && !isDark
            ? [
                BoxShadow(
                  color: PinTokens.shadowForest.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: PinTokens.radiusFull,
                child: content,
              ),
            )
          : content,
    );
  }
}
