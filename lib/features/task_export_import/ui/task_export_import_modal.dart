import 'package:flutter/material.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'components/export_blueprint_tab.dart';
import 'components/export_calendar_tab.dart';
import 'components/export_text_tab.dart';
import 'components/import_blueprint_tab.dart';
import 'components/import_text_tab.dart';

/// Modal dialog providing comprehensive offline export, import, text sharing, and calendar integration.
class TaskExportImportModal extends StatefulWidget {
  /// Optional initial tab index (0 = Export, 1 = Import).
  final int initialTabIndex;

  const TaskExportImportModal({super.key, this.initialTabIndex = 0});

  /// Displays the modal dialog.
  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => TaskExportImportModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<TaskExportImportModal> createState() => _TaskExportImportModalState();
}

class _TaskExportImportModalState extends State<TaskExportImportModal>
    with SingleTickerProviderStateMixin {
  late final TabController _primaryTabController;
  int _exportSubView = 0; // 0: Text, 1: Calendar, 2: Blueprint
  int _importSubView = 0; // 0: Blueprint, 1: Text Notes

  @override
  void initState() {
    super.initState();
    _primaryTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _primaryTabController.dispose();
    super.dispose();
  }

  void _onImportComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pins imported successfully!'),
        backgroundColor: PinTokens.accentEmerald,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(PinTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_alt_rounded, size: 22, color: PinTokens.accentEmerald),
                      const SizedBox(width: 8),
                      Text(
                        'Transfer & Share Pins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  PinButton.icon(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Primary TabBar (Export vs Import)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? PinTokens.darkCanvasBg : PinTokens.surfaceColumn,
                  borderRadius: PinTokens.radiusMd,
                ),
                child: TabBar(
                  controller: _primaryTabController,
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
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(icon: Icon(Icons.upload_rounded, size: 16), text: 'Share & Export'),
                    Tab(icon: Icon(Icons.download_rounded, size: 16), text: 'Import Pins'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sub-selector Bar
              AnimatedBuilder(
                animation: _primaryTabController,
                builder: (context, _) {
                  final isExport = _primaryTabController.index == 0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: isExport
                          ? [
                              _buildSubChip('Text Note', 0, _exportSubView, (i) => setState(() => _exportSubView = i), isDark),
                              const SizedBox(width: 8),
                              _buildSubChip('Calendar Event', 1, _exportSubView, (i) => setState(() => _exportSubView = i), isDark),
                              const SizedBox(width: 8),
                              _buildSubChip('Portable Blueprint', 2, _exportSubView, (i) => setState(() => _exportSubView = i), isDark),
                            ]
                          : [
                              _buildSubChip('From Blueprint / JSON', 0, _importSubView, (i) => setState(() => _importSubView = i), isDark),
                              const SizedBox(width: 8),
                              _buildSubChip('From Text / Checklist', 1, _importSubView, (i) => setState(() => _importSubView = i), isDark),
                            ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Content View
              Expanded(
                child: TabBarView(
                  controller: _primaryTabController,
                  children: [
                    _buildExportContentView(),
                    _buildImportContentView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportContentView() {
    switch (_exportSubView) {
      case 1:
        return const ExportCalendarTab();
      case 2:
        return const ExportBlueprintTab();
      case 0:
      default:
        return const ExportTextTab();
    }
  }

  Widget _buildImportContentView() {
    switch (_importSubView) {
      case 1:
        return ImportTextTab(onImportComplete: _onImportComplete);
      case 0:
      default:
        return ImportBlueprintTab(onImportComplete: _onImportComplete);
    }
  }

  Widget _buildSubChip(
    String label,
    int index,
    int currentIndex,
    ValueChanged<int> onSelect,
    bool isDark,
  ) {
    final isSelected = index == currentIndex;
    final activeBg = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final inactiveBg = isDark ? PinTokens.darkCardBg : PinTokens.surfaceColumn;
    final activeFg = isDark ? PinTokens.darkCanvasBg : Colors.white;
    final inactiveFg = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return InkWell(
      borderRadius: PinTokens.radiusSm,
      onTap: () => onSelect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: PinTokens.radiusSm,
          border: Border.all(
            color: isSelected ? activeBg : (isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
