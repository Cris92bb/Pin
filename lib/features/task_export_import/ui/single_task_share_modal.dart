import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'components/single_task_blueprint_tab.dart';
import 'components/single_task_calendar_tab.dart';
import 'components/single_task_link_tab.dart';
import 'components/single_task_text_tab.dart';

/// Tactile modal dialog for sharing an individual Pin via Text, Calendar, or Blueprint code.
class SingleTaskShareModal extends StatefulWidget {
  final PinTask task;

  const SingleTaskShareModal({super.key, required this.task});

  /// Displays the modal dialog.
  static Future<void> show(BuildContext context, {required PinTask task}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => SingleTaskShareModal(task: task),
    );
  }

  @override
  State<SingleTaskShareModal> createState() => _SingleTaskShareModalState();
}

class _SingleTaskShareModalState extends State<SingleTaskShareModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Dialog(
      backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusLg,
        side: BorderSide(
          color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(PinTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.share_rounded, size: 18, color: PinTokens.accentEmerald),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Share Pin: ${widget.task.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PinButton.icon(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDark ? PinTokens.darkCanvasBg : PinTokens.surfaceColumn,
                  borderRadius: PinTokens.radiusMd,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: isDark ? PinTokens.darkSheetBg : PinTokens.surfaceCard,
                    borderRadius: PinTokens.radiusMd,
                    border: Border.all(
                      color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
                    ),
                  ),
                  labelColor: textPrimary,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(icon: Icon(Icons.link_rounded, size: 15), text: 'Link'),
                    Tab(icon: Icon(Icons.notes_rounded, size: 15), text: 'Text'),
                    Tab(icon: Icon(Icons.event_available_rounded, size: 15), text: 'Calendar'),
                    Tab(icon: Icon(Icons.qr_code_2_rounded, size: 15), text: 'Blueprint'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleTaskLinkTab(task: widget.task),
                    SingleTaskTextTab(task: widget.task),
                    SingleTaskCalendarTab(task: widget.task),
                    SingleTaskBlueprintTab(task: widget.task),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
