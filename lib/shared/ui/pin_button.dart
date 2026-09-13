import 'package:flutter/material.dart';
import 'pin_tokens.dart';

enum PinButtonVariant { primary, secondary, ghost, danger }

/// Sleek desktop button with hover feedback and calm styling.
class PinButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PinButtonVariant variant;
  final bool isCompact;
  final String? tooltip;

  final double? width;

  const PinButton({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
    this.variant = PinButtonVariant.secondary,
    this.isCompact = false,
    this.tooltip,
    this.width,
  });

  const PinButton.primary({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isCompact = false,
    this.tooltip,
    this.width,
  })  : variant = PinButtonVariant.primary;

  const PinButton.icon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = PinButtonVariant.ghost,
    this.isCompact = true,
    this.tooltip,
    this.width,
  })  : text = null;

  @override
  State<PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<PinButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (widget.variant) {
      case PinButtonVariant.primary:
        if (isDark) {
          bg = _isHovered
              ? PinTokens.accentEmerald.withValues(alpha: 0.85)
              : PinTokens.accentEmerald;
          fg = PinTokens.textInverse;
        } else {
          bg = _isHovered
              ? const Color(0xFF223028)
              : PinTokens.lightFabBg;
          fg = PinTokens.textInverse;
        }
        border = Colors.transparent;
        break;
      case PinButtonVariant.secondary:
        if (isDark) {
          bg = _isHovered ? PinTokens.surfaceCardHover : PinTokens.surfaceCard;
          fg = PinTokens.darkTextPrimary;
          border = _isHovered ? PinTokens.borderFocus : PinTokens.borderDefault;
        } else {
          bg = _isHovered ? PinTokens.lightStackedTabBg : PinTokens.lightTagBg;
          fg = PinTokens.lightTextPrimary;
          border = _isHovered ? PinTokens.lightBorder : PinTokens.lightBorderSubtle;
        }
        break;
      case PinButtonVariant.ghost:
        if (isDark) {
          bg = _isHovered
              ? PinTokens.surfaceCardHover.withValues(alpha: 0.6)
              : Colors.transparent;
          fg = _isHovered ? PinTokens.darkTextPrimary : PinTokens.darkTextSecondary;
          border = Colors.transparent;
        } else {
          bg = _isHovered
              ? PinTokens.lightTagBg.withValues(alpha: 0.6)
              : Colors.transparent;
          fg = _isHovered ? PinTokens.lightTextPrimary : PinTokens.lightTextSecondary;
          border = Colors.transparent;
        }
        break;
      case PinButtonVariant.danger:
        if (isDark) {
          bg = _isHovered
              ? PinTokens.accentRose.withValues(alpha: 0.25)
              : PinTokens.accentRose.withValues(alpha: 0.12);
          fg = PinTokens.accentRose;
          border = PinTokens.accentRose.withValues(alpha: 0.4);
        } else {
          bg = _isHovered
              ? const Color(0xFFFDE8E8)
              : const Color(0xFFFDF2F2);
          fg = const Color(0xFFB91C1C);
          border = const Color(0xFFFCA5A5).withValues(alpha: 0.5);
        }
        break;
    }

    final verticalPadding = widget.isCompact ? 6.0 : 9.0;
    final horizontalPadding = widget.width != null
        ? 6.0
        : (widget.text == null
            ? verticalPadding
            : (widget.isCompact ? 10.0 : 14.0));

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: PinTokens.animFast,
          width: widget.width,
          alignment: widget.width != null ? Alignment.center : null,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: widget.onPressed == null ? bg.withValues(alpha: 0.4) : bg,
            borderRadius: PinTokens.radiusMd,
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: widget.isCompact ? 16 : 18,
                  color: widget.onPressed == null ? fg.withValues(alpha: 0.5) : fg,
                ),
                if (widget.text != null) SizedBox(width: widget.isCompact ? 6 : 8),
              ],
              if (widget.text != null)
                Text(
                  widget.text!,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: widget.onPressed == null ? fg.withValues(alpha: 0.5) : fg,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 400),
        child: button,
      );
    }

    return button;
  }
}
