import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/board/model/board.dart';
import '../../../../entities/board/state/board_providers.dart';
import '../../../../entities/task/state/task_providers.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Helper dialog utilities for creating and renaming boards.
class BoardDialogs {
  const BoardDialogs._();

  /// Displays dialog to create a new board.
  static void showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg,
        title: Text(
          'Create Board',
          style: TextStyle(
            color: isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Work, Study, Freelance',
            hintStyle: TextStyle(
              color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
            ),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              Navigator.pop(dialogCtx);
              ref.read(boardStateProvider.notifier).createBoard(val.trim()).then((b) {
                ref.read(taskStateProvider.notifier).setActiveBoard(b.id, wipLimit: b.wipLimit);
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                ref.read(boardStateProvider.notifier).createBoard(name).then((b) {
                  ref.read(taskStateProvider.notifier).setActiveBoard(b.id, wipLimit: b.wipLimit);
                });
              }
            },
            child: Text(
              'Create',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays dialog to rename an existing board.
  static void showRenameDialog(BuildContext context, WidgetRef ref, Board board) {
    final controller = TextEditingController(text: board.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg,
        title: Text(
          'Rename Board',
          style: TextStyle(
            color: isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(boardStateProvider.notifier).renameBoard(board.id, newName);
                Navigator.pop(dialogCtx);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
