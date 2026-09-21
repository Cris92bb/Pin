import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../entities/task/model/pin_task.dart';
import '../../features/ai/ui/ai_task_breakdown_modal.dart';
import '../../features/task_crud/ui/task_crud_modal.dart';
import '../../features/task_export_import/ui/single_task_share_modal.dart';
import '../../shared/ui/pin_tokens.dart';
import 'components/bubble_action_button.dart';
import 'components/task_action_mobile_sheet.dart';

/// Tactile floating action bubble menu revealing quick options:
/// 1. ✨ AI Breakdown & Re-Analysis
/// 2. ✏️ Edit Pin
/// 3. 📤 Share Pin (Text, Calendar, Blueprint)
/// 4. 🗑️ Delete Pin
class TaskActionBubble extends StatelessWidget {
  final PinTask task;
  final VoidCallback? onAiBreakdown;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const TaskActionBubble({
    super.key,
    required this.task,
    this.onAiBreakdown,
    this.onEdit,
    this.onShare,
    this.onDelete,
  });

  /// Displays the action bubble positioned near [targetPosition] or centered on screen.
  static Future<T?> show<T>(
    BuildContext context, {
    required PinTask task,
    Offset? targetPosition,
    VoidCallback? onAiBreakdown,
    VoidCallback? onEdit,
    VoidCallback? onShare,
    VoidCallback? onDelete,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss action bubble',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final isMobile = MediaQuery.of(dialogContext).size.width < 500;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        if (isMobile) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: animation, child: child),
          );
        }

        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final screenSize = MediaQuery.of(dialogContext).size;
        final isMobile = screenSize.width < 500;

        final bubble = Material(
          type: MaterialType.transparency,
          child: TaskActionBubble(
            task: task,
            onAiBreakdown: () {
              Navigator.of(dialogContext).pop();
              if (onAiBreakdown != null) {
                onAiBreakdown();
              } else {
                AiTaskBreakdownModal.show(
                  context,
                  task: task,
                  onOpenEditor: (t) => TaskCrudModal.show(context, task: t),
                );
              }
            },
            onEdit: () {
              Navigator.of(dialogContext).pop();
              onEdit != null ? onEdit() : TaskCrudModal.show(context, task: task);
            },
            onShare: () {
              Navigator.of(dialogContext).pop();
              onShare != null ? onShare() : SingleTaskShareModal.show(context, task: task);
            },
            onDelete: () {
              Navigator.of(dialogContext).pop();
              onDelete?.call();
            },
          ),
        );

        if (isMobile) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: bubble,
              ),
            ),
          );
        }

        // Calculate clamped position so the bubble hovers right around the click/touch point
        double? left;
        double? top;

        if (targetPosition != null) {
          const estimatedWidth = 480.0;
          const estimatedHeight = 56.0;

          left = (targetPosition.dx - estimatedWidth / 2)
              .clamp(16.0, math.max(16.0, screenSize.width - estimatedWidth - 16.0));

          top = targetPosition.dy > estimatedHeight + 30
              ? targetPosition.dy - estimatedHeight - 14
              : targetPosition.dy + 20;
          top = top.clamp(16.0, math.max(16.0, screenSize.height - estimatedHeight - 16.0));
        }

        if (left != null && top != null) {
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: bubble,
              ),
            ],
          );
        }

        return Center(child: bubble);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    if (isMobile) {
      return TaskActionMobileSheet(
        task: task,
        onAiBreakdown: onAiBreakdown,
        onEdit: onEdit,
        onShare: onShare,
        onDelete: onDelete,
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? PinTokens.darkActionBubbleBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkActionBubbleBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: PinTokens.radiusFull,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : PinTokens.shadowSlate)
                .withValues(alpha: isDark ? 0.55 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: PinTokens.aiAccentViolet.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option 1: AI Breakdown
          BubbleActionButton(
            icon: Icons.auto_awesome_rounded,
            iconColor: PinTokens.aiAccentVioletLight,
            label: 'AI Breakdown',
            subtitle: 'Re-analyze',
            labelColor: PinTokens.aiAccentVioletLight,
            subtitleColor:
                PinTokens.aiAccentVioletSubtle.withValues(alpha: 0.8),
            hoverBgColor: PinTokens.aiAccentViolet
                .withValues(alpha: isDark ? 0.18 : 0.10),
            onTap: onAiBreakdown,
          ),
          _buildDivider(borderColor),

          // Option 2: Edit Pin
          BubbleActionButton(
            icon: Icons.edit_rounded,
            iconColor: textPrimary,
            label: 'Edit Pin',
            subtitle: 'Full editor',
            labelColor: textPrimary,
            subtitleColor: textSecondary,
            hoverBgColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            onTap: onEdit,
          ),
          _buildDivider(borderColor),

          // Option 3: Share Pin
          BubbleActionButton(
            icon: Icons.share_rounded,
            iconColor: PinTokens.accentEmerald,
            label: 'Share',
            subtitle: 'Text & Cal',
            labelColor: PinTokens.accentEmerald,
            subtitleColor: textSecondary,
            hoverBgColor: PinTokens.accentEmerald
                .withValues(alpha: isDark ? 0.18 : 0.10),
            onTap: onShare,
          ),
          _buildDivider(borderColor),

          // Option 4: Delete Pin
          BubbleActionButton(
            icon: Icons.delete_outline_rounded,
            iconColor: PinTokens.accentRose,
            label: 'Delete',
            subtitle: 'Remove pin',
            labelColor: PinTokens.accentRose,
            subtitleColor: isDark
                ? PinTokens.darkTextSecondary
                : PinTokens.lightTextSecondary,
            hoverBgColor: PinTokens.accentRose
                .withValues(alpha: isDark ? 0.18 : 0.10),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) => Container(
        width: 1.2,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: color,
      );
}
