import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Tactile mobile contextual action sheet for a single [PinTask].
///
/// Displayed on smartphone and compact viewports (< 500px width)
/// to provide thumb-friendly vertical tap targets without horizontal overflow.
class TaskActionMobileSheet extends StatelessWidget {
  final PinTask task;
  final VoidCallback? onAiBreakdown;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const TaskActionMobileSheet({
    super.key,
    required this.task,
    this.onAiBreakdown,
    this.onEdit,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? PinTokens.darkCardBg : PinTokens.surfaceModal;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.borderDefault;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: PinTokens.radiusLg,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.2 : 1.0,
        ),
        boxShadow: isDark ? PinTokens.darkCardShadow : PinTokens.lightCardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: PinTokens.radiusFull,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header Row with Pin Title
          Row(
            children: [
              const Icon(Icons.push_pin_rounded, size: 16, color: PinTokens.accentEmerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              InkWell(
                borderRadius: PinTokens.radiusFull,
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 6),

          // Action 1: AI Breakdown
          _buildActionTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: PinTokens.aiAccentVioletLight,
            label: 'AI Breakdown',
            subtitle: 'Re-analyze',
            labelColor: PinTokens.aiAccentVioletLight,
            subtitleColor: textSecondary,
            hoverColor: PinTokens.aiAccentViolet.withValues(alpha: isDark ? 0.16 : 0.08),
            onTap: onAiBreakdown,
          ),

          // Action 2: Edit Pin
          _buildActionTile(
            icon: Icons.edit_rounded,
            iconColor: textPrimary,
            label: 'Edit Pin',
            subtitle: 'Full editor',
            labelColor: textPrimary,
            subtitleColor: textSecondary,
            hoverColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            onTap: onEdit,
          ),

          // Action 3: Share Pin
          _buildActionTile(
            icon: Icons.share_rounded,
            iconColor: PinTokens.accentEmerald,
            label: 'Share',
            subtitle: 'Text & Cal',
            labelColor: PinTokens.accentEmerald,
            subtitleColor: textSecondary,
            hoverColor: PinTokens.accentEmerald.withValues(alpha: isDark ? 0.16 : 0.08),
            onTap: onShare,
          ),

          // Action 4: Delete Pin
          _buildActionTile(
            icon: Icons.delete_outline_rounded,
            iconColor: PinTokens.accentRose,
            label: 'Delete',
            subtitle: 'Remove pin',
            labelColor: PinTokens.accentRose,
            subtitleColor: textSecondary,
            hoverColor: PinTokens.accentRose.withValues(alpha: isDark ? 0.16 : 0.08),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required Color labelColor,
    required Color subtitleColor,
    required Color hoverColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: PinTokens.radiusMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hoverColor,
                borderRadius: PinTokens.radiusSm,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: subtitleColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
