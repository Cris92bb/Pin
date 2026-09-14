import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/focus_mode/ui/focus_mode_view.dart';
import '../../features/task_crud/ui/task_crud_modal.dart';
import '../../features/task_crud/state/task_editor_state.dart';
import '../../features/task_export_import/ui/task_export_import_modal.dart';
import '../../shared/ui/pin_breakpoints.dart';
import '../../shared/ui/pin_tokens.dart';
import '../../widgets/kanban_board/layered_deck_view.dart';
import '../../widgets/kanban_board/wide_fold_kanban_view.dart';
import '../../features/ai/ui/ai_settings_modal.dart';
import '../../features/sync/ui/firebase_account_modal.dart';
import '../../features/sync/ui/sync_status_badge.dart';
import '../../features/wearable/ui/wearable_home_page.dart';

/// The primary companion view assembling the mobile/companion frame,
/// layered card deck, header with dynamic notch, and quick actions.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _openCreateTaskModal([TaskStatus? defaultStatus]) {
    final activeDeck = ref.read(activeDeckProvider);
    final isTodayFull = ref.read(taskStateProvider).isTodayWipFull;
    final initialDeck = defaultStatus ??
        (activeDeck == TaskStatus.today && isTodayFull
            ? TaskStatus.backlog
            : activeDeck);

    final isWide = PinBreakpoints.isWide(context);
    if (isWide) {
      ref.read(activeTaskEditorProvider.notifier).state =
          TaskEditorArgs(defaultStatus: initialDeck);
    } else {
      TaskCrudModal.show(context, defaultStatus: initialDeck);
    }
  }

  void _openFocusModeFirstToday() {
    final state = ref.read(taskStateProvider);
    if (state.todayTasks.isNotEmpty) {
      ref.read(activeFocusTaskProvider.notifier).state = state.todayTasks.first;
    } else if (state.backlogTasks.isNotEmpty) {
      ref.read(activeFocusTaskProvider.notifier).state = state.backlogTasks.first;
    } else {
      _openCreateTaskModal(TaskStatus.today);
    }
  }

  void _openExportImportModal() {
    TaskExportImportModal.show(context);
  }

  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.read(themeModeProvider.notifier).state =
        isDark ? ThemeMode.light : ThemeMode.dark;
  }

  void _exitApplication() {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        const MethodChannel('pin/window').invokeMethod('close');
      }
    } catch (_) {}
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenTier = PinBreakpoints.getTier(context);
    if (screenTier == PinScreenTier.xs) {
      return const WearableHomePage();
    }

    final activeFocusTask = ref.watch(activeFocusTaskProvider);
    final taskState = ref.watch(taskStateProvider);
    final notifier = ref.read(taskStateProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenTier == PinScreenTier.wide;

    final frameBg = isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightPhoneFrameBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    // If Focus Mode is active on a compact / small screen, render full-width edge-to-edge Focus Mode view
    if (activeFocusTask != null && !isWide) {
      return Scaffold(
        backgroundColor: frameBg,
        body: SafeArea(
          child: Stack(
            children: [
              FocusModeView(
                task: activeFocusTask,
                onExit: () {
                  ref.read(activeFocusTaskProvider.notifier).state = null;
                },
              ),
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 10,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) {
                        const MethodChannel('pin/window')
                            .invokeMethod('resize', {'edge': 'south'});
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;

          if (event.logicalKey == LogicalKeyboardKey.keyN) {
            _openCreateTaskModal(TaskStatus.today);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.keyF && !isCtrlOrCmd) {
            _openFocusModeFirstToday();
            return KeyEventResult.handled;
          } else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyE) {
            _openExportImportModal();
            return KeyEventResult.handled;
          } else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyI) {
            _openExportImportModal();
            return KeyEventResult.handled;
          } else if (isCtrlOrCmd &&
              (event.logicalKey == LogicalKeyboardKey.keyQ ||
                  event.logicalKey == LogicalKeyboardKey.keyW)) {
            _exitApplication();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.digit1 && !isCtrlOrCmd) {
            ref.read(activeDeckProvider.notifier).state = TaskStatus.backlog;
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.digit2 && !isCtrlOrCmd) {
            ref.read(activeDeckProvider.notifier).state = TaskStatus.today;
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.digit3 && !isCtrlOrCmd) {
            ref.read(activeDeckProvider.notifier).state = TaskStatus.done;
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && !isCtrlOrCmd) {
            final current = ref.read(activeDeckProvider);
            const order = [TaskStatus.backlog, TaskStatus.today, TaskStatus.done];
            final idx = order.indexOf(current);
            if (idx > 0) {
              ref.read(activeDeckProvider.notifier).state = order[idx - 1];
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && !isCtrlOrCmd) {
            final current = ref.read(activeDeckProvider);
            const order = [TaskStatus.backlog, TaskStatus.today, TaskStatus.done];
            final idx = order.indexOf(current);
            if (idx < order.length - 1) {
              ref.read(activeDeckProvider.notifier).state = order[idx + 1];
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            notifier.dismissAlert();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: isWide
            ? (isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg)
            : frameBg,
        body: Center(
          child: Container(
            width: isWide
                ? (screenWidth > PinBreakpoints.wideMaxWidth
                    ? PinBreakpoints.wideMaxWidth
                    : screenWidth - 32)
                : double.infinity,
            height: isWide
                ? (screenHeight > 540 ? screenHeight - 32 : screenHeight)
                : double.infinity,
            constraints: isWide
                ? BoxConstraints(
                    maxWidth: PinBreakpoints.wideMaxWidth,
                    maxHeight: screenHeight > 540 ? screenHeight - 20 : screenHeight,
                    minHeight: 480,
                  )
                : null,
            decoration: BoxDecoration(
              color: frameBg,
              borderRadius: isWide ? BorderRadius.circular(32) : BorderRadius.zero,
              border: isWide
                  ? Border.all(
                      color: isDark ? borderColor : const Color(0x1F0F172A),
                      width: 1.0,
                    )
                  : null,
              boxShadow: isWide
                  ? [
                      BoxShadow(
                        color: (isDark ? Colors.black : const Color(0xFF0F172A))
                            .withValues(alpha: isDark ? 0.45 : 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: isWide ? BorderRadius.circular(30) : BorderRadius.zero,
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Companion App Top Bar (Logo, Dynamic Island notch, Theme toggle, Options)
                        _buildCompanionHeader(isDark, textPrimary, taskState, notifier),

                        // WIP Alert Banner (if WIP exceeded)
                        if (taskState.alertMessage != null)
                          _buildWipAlertBanner(taskState.alertMessage!, notifier),

                        const SizedBox(height: 8),

                        // Kanban View (Wide 3-drawer on web & fold, layered deck on narrow phone)
                        Expanded(
                          child: isWide
                              ? const WideFoldKanbanView()
                              : const LayeredDeckView(),
                        ),
                      ],
                    ),

                    // Floating Action Button (+) centered at bottom
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildFloatingActionButton(isDark, borderColor),
                      ),
                    ),

                    // Top window height resize handle
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 5,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (_) {
                            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
                              const MethodChannel('pin/window')
                                  .invokeMethod('resize', {'edge': 'north'});
                            }
                          },
                        ),
                      ),
                    ),

                    // Bottom window height resize handle
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 10,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (_) {
                            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
                              const MethodChannel('pin/window')
                                  .invokeMethod('resize', {'edge': 'south'});
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanionHeader(
    bool isDark,
    Color textPrimary,
    TaskListState taskState,
    TaskStateNotifier notifier,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
          const MethodChannel('pin/window').invokeMethod('drag');
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 14, 6),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bold Display Brand "Pin"
          Text(
            'Pin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: textPrimary,
            ),
          ),

          const Spacer(),

          // Right Controls: Cloud Sync Badge, Theme Toggle & Menu horizontally aligned
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cloud Sync Status Badge
              const SyncStatusBadge(),

              const SizedBox(width: 6),

              // Theme Toggle Button
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _toggleTheme,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? PinTokens.darkActionThemeBg : PinTokens.headerThemeBgLight,
                    border: Border.all(
                      color: isDark ? PinTokens.darkBorder : PinTokens.headerThemeBorderLight,
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                    size: 16,
                    color: isDark ? PinTokens.darkActionThemeFg : PinTokens.headerThemeFgLight,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Options Menu (...)
              PopupMenuButton<String>(
                tooltip: 'Options',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: textPrimary,
                ),
                color: isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: PinTokens.radiusMd,
                  side: BorderSide(
                    color: isDark ? PinTokens.darkBorder : PinTokens.lightBorder,
                  ),
                ),
                onSelected: (val) {
                  switch (val) {
                    case 'cloud_sync':
                      FirebaseAccountModal.show(context);
                      break;
                    case 'wip_4':
                      notifier.setWipLimit(4);
                      break;
                    case 'wip_5':
                      notifier.setWipLimit(5);
                      break;
                    case 'blueprints':
                      _openExportImportModal();
                      break;
                    case 'ai_settings':
                      AiSettingsModal.show(context);
                      break;
                    case 'clear_done':
                      notifier.clearDoneTasks();
                      break;
                    case 'focus_first':
                      _openFocusModeFirstToday();
                      break;
                    case 'system_theme':
                      ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                      break;
                    case 'exit':
                      _exitApplication();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'focus_first',
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('Focus Active Pin')),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: taskState.wipLimit == 5 ? 'wip_4' : 'wip_5',
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            taskState.wipLimit == 5
                                ? 'Switch WIP Limit to 4'
                                : 'Switch WIP Limit to 5',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cloud_sync',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_sync_rounded, size: 16, color: PinTokens.primary),
                        SizedBox(width: 8),
                        Expanded(child: Text('Cloud Sync & Account')),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'blueprints',
                    child: Row(
                      children: [
                        Icon(Icons.sync_alt_rounded, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('Blueprints (Import / Export)')),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ai_settings',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: PinTokens.primary),
                        SizedBox(width: 8),
                        Expanded(child: Text('Gemini AI Settings')),
                      ],
                    ),
                  ),
                  if (ref.watch(themeModeProvider) != ThemeMode.system) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'system_theme',
                      child: Row(
                        children: [
                          Icon(Icons.brightness_auto_rounded, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Use System Theme')),
                        ],
                      ),
                    ),
                  ],
                  if (taskState.doneTasks.isNotEmpty) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'clear_done',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined,
                              size: 16, color: PinTokens.accentRose),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Clear Done Pins',
                              style: TextStyle(color: PinTokens.accentRose),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'exit',
                    child: Row(
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            size: 16, color: PinTokens.accentRose),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Exit',
                            style: TextStyle(color: PinTokens.accentRose),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFloatingActionButton(bool isDark, Color borderColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _openCreateTaskModal(),
      child: Container(
        width: 68,
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? PinTokens.darkFabBg : PinTokens.lightFabBg,
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(color: PinTokens.darkBorder, width: 1.0)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : PinTokens.lightFabBg)
                  .withValues(alpha: isDark ? 0.4 : 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 28,
            color: isDark ? PinTokens.darkTextPrimary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWipAlertBanner(String message, TaskStateNotifier notifier) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PinTokens.accentAmber.withValues(alpha: 0.15),
        borderRadius: PinTokens.radiusMd,
        border: Border.all(color: PinTokens.accentAmber, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: PinTokens.accentAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PinTokens.accentAmber,
              ),
            ),
          ),
          InkWell(
            onTap: notifier.dismissAlert,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: PinTokens.accentAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
