import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/board/state/board_providers.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'board_selector_modal.dart';

/// A tactile interactive pill chip displayed in the companion header
/// showing the active board with a dropdown chevron to switch workspaces.
class BoardSwitcherChip extends ConsumerWidget {
  const BoardSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBoard = ref.watch(activeBoardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? PinTokens.darkCardBg : PinTokens.headerThemeBgLight;
    final border = isDark ? PinTokens.darkBorder : PinTokens.headerThemeBorderLight;
    final fg = isDark ? PinTokens.darkTextPrimary : PinTokens.headerThemeFgLight;
    final subtle = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => BoardSelectorModal.show(context),
        borderRadius: PinTokens.radiusFull,
        hoverColor: isDark
            ? PinTokens.darkFabBg.withValues(alpha: 0.3)
            : PinTokens.lightBorder.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: PinTokens.radiusFull,
            border: Border.all(color: border, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                activeBoard.id == 'projects'
                    ? Icons.folder_outlined
                    : Icons.person_outline_rounded,
                size: 14,
                color: subtle,
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  activeBoard.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
