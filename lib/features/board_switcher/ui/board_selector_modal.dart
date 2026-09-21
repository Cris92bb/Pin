import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/board/state/board_providers.dart';
import '../../../entities/task/state/task_providers.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'components/board_dialogs.dart';
import 'components/multi_board_pro_banner.dart';

/// Modal bottom sheet allowing users to switch between boards (e.g., Personal, Projects),
/// create new boards, rename boards, or manage board workspaces.
class BoardSelectorModal extends ConsumerWidget {
  const BoardSelectorModal({super.key});

  /// Displays the board selector modal as a bottom sheet.
  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? PinTokens.darkSheetBg : PinTokens.lightSheetBg;

    return showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => const BoardSelectorModal(),
    );
  }

  void _showEnablePrompt(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg,
        title: Text(
          'Multi-Board Workspaces',
          style: TextStyle(
            color: isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Multiple boards is a Pro capability. Enable the feature toggle to create and manage separate workspaces.',
          style: TextStyle(
            color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(boardStateProvider.notifier).setMultiBoardEnabled(true);
              BoardDialogs.showCreateDialog(context, ref);
            },
            child: const Text('Enable & Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardStateProvider);
    final taskState = ref.watch(taskStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final border = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final activeBg = isDark
        ? PinTokens.darkFabBg.withValues(alpha: 0.5)
        : PinTokens.lightTagBg;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Text(
                  'Workspaces',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Create New Board',
                  icon: const Icon(Icons.add_rounded, size: 22),
                  color: textPrimary,
                  onPressed: () {
                    if (!boardState.isMultiBoardEnabled) {
                      _showEnablePrompt(context, ref);
                    } else {
                      BoardDialogs.showCreateDialog(context, ref);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Board List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: boardState.boards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final board = boardState.boards[index];
                  final isActive = board.id == boardState.activeBoardId;
                  final tasksCount = taskState.tasksForBoard(board.id).length;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(boardStateProvider.notifier).selectBoard(board.id);
                        ref.read(taskStateProvider.notifier).setActiveBoard(
                              board.id,
                              wipLimit: board.wipLimit,
                            );
                        Navigator.pop(context);
                      },
                      borderRadius: PinTokens.radiusCard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? activeBg : cardBg,
                          borderRadius: PinTokens.radiusCard,
                          border: Border.all(
                            color: isActive
                                ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus)
                                : border,
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              board.id == 'projects'
                                  ? Icons.folder_outlined
                                  : Icons.person_outline_rounded,
                              size: 18,
                              color: isActive
                                  ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus)
                                  : textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    board.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$tasksCount ${tasksCount == 1 ? "task" : "tasks"} • WIP ${board.wipLimit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus,
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                              color: cardBg,
                              onSelected: (action) {
                                if (action == 'rename') {
                                  BoardDialogs.showRenameDialog(context, ref, board);
                                } else if (action == 'delete') {
                                  ref.read(boardStateProvider.notifier).deleteBoard(board.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Rename'),
                                ),
                                if (boardState.boards.length > 1)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: PinTokens.dangerFgLight),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            const MultiBoardProBanner(),
          ],
        ),
      ),
    );
  }
}
