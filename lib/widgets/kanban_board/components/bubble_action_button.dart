import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Interactive action button item within the floating [TaskActionBubble].
///
/// Architecture & Role:
/// - Layer: `widgets/kanban_board/components` (Feature-Sliced Design v2.1)
/// - Single responsibility: Render an icon, label, and subtitle with hover feedback.
class BubbleActionButton extends StatefulWidget {
  /// The leading action icon.
  final IconData icon;

  /// Icon tint color.
  final Color iconColor;

  /// Primary label text.
  final String label;

  /// Secondary subtitle text.
  final String subtitle;

  /// Primary label text color.
  final Color labelColor;

  /// Subtitle text color.
  final Color subtitleColor;

  /// Container background color when hovered.
  final Color hoverBgColor;

  /// Callback when this action is tapped.
  final VoidCallback? onTap;

  /// Creates a [BubbleActionButton].
  const BubbleActionButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.labelColor,
    required this.subtitleColor,
    required this.hoverBgColor,
    this.onTap,
  });

  @override
  State<BubbleActionButton> createState() => _BubbleActionButtonState();
}

class _BubbleActionButtonState extends State<BubbleActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: PinTokens.radiusFull,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PinTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverBgColor : Colors.transparent,
            borderRadius: PinTokens.radiusFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.iconColor,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: widget.labelColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: widget.subtitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
