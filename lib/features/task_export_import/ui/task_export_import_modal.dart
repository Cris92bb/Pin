import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/lib/blueprint_codec.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Modal dialog providing offline JSON/Base64 blueprint export & import via clipboard.
class TaskExportImportModal extends ConsumerStatefulWidget {
  const TaskExportImportModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const TaskExportImportModal(),
    );
  }

  @override
  ConsumerState<TaskExportImportModal> createState() =>
      _TaskExportImportModalState();
}

class _TaskExportImportModalState
    extends ConsumerState<TaskExportImportModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _importInputController;

  String? _exportBlueprint;
  bool _copied = false;

  BlueprintDecodeResult? _decodeResult;
  String? _importErrorMessage;
  bool _importSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _importInputController = TextEditingController();
    _generateExportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importInputController.dispose();
    super.dispose();
  }

  void _generateExportData() {
    final tasks = ref.read(taskStateProvider).tasks;
    final jsonList = tasks.map((t) => t.toJson()).toList();
    _exportBlueprint = BlueprintCodec.encodeTasks(jsonList);
  }

  Future<void> _copyToClipboard(String content, String message) async {
    await Clipboard.setData(ClipboardData(text: content));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _importInputController.text = data.text!;
      _onImportInputChanged(data.text!);
    }
  }

  void _onImportInputChanged(String value) {
    setState(() {
      _importErrorMessage = null;
      _importSuccess = false;
      if (value.trim().isEmpty) {
        _decodeResult = null;
      } else {
        _decodeResult = BlueprintCodec.decode(value);
        if (!_decodeResult!.isSuccess) {
          _importErrorMessage = _decodeResult!.errorMessage;
        }
      }
    });
  }

  Future<void> _executeImport({bool replaceAll = false}) async {
    if (_decodeResult == null || !_decodeResult!.isSuccess) return;

    try {
      final tasks =
          _decodeResult!.tasks.map((m) => PinTask.fromJson(m)).toList();
      final notifier = ref.read(taskStateProvider.notifier);
      await notifier.importTasks(tasks, replaceAll: replaceAll);

      setState(() {
        _importSuccess = true;
        _importErrorMessage = null;
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _importErrorMessage = 'Failed to load parsed tasks: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PinTokens.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: PinTokens.radiusLg,
        side: BorderSide(color: PinTokens.borderDefault, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(PinTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Blueprint Transfer (Offline)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PinTokens.textPrimary,
                    ),
                  ),
                  PinButton.icon(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tab bar
              Container(
                decoration: const BoxDecoration(
                  color: PinTokens.surfaceColumn,
                  borderRadius: PinTokens.radiusMd,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const BoxDecoration(
                    color: PinTokens.surfaceCard,
                    borderRadius: PinTokens.radiusMd,
                    border: Border.fromBorderSide(
                        BorderSide(color: PinTokens.borderDefault)),
                  ),
                  labelColor: PinTokens.textPrimary,
                  unselectedLabelColor: PinTokens.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.upload_rounded, size: 16),
                      text: 'Export Blueprint',
                    ),
                    Tab(
                      icon: Icon(Icons.download_rounded, size: 16),
                      text: 'Import Blueprint',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExportTab(),
                    _buildImportTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    final tasks = ref.watch(taskStateProvider).tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exporting ${tasks.length} task${tasks.length == 1 ? '' : 's'} as a portable blueprint.',
          style: const TextStyle(fontSize: 13, color: PinTokens.textSecondary),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PinTokens.canvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(color: PinTokens.borderDefault),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _exportBlueprint ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: PinTokens.accentEmerald,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton.primary(
              icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
              text: _copied ? 'Copied to Clipboard!' : 'Copy Blueprint',
              onPressed: _exportBlueprint != null
                  ? () => _copyToClipboard(
                        _exportBlueprint!,
                        'Blueprint copied to clipboard',
                      )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paste a Base64 or JSON blueprint below:',
              style: TextStyle(fontSize: 13, color: PinTokens.textSecondary),
            ),
            PinButton(
              icon: Icons.paste_rounded,
              text: 'Paste from Clipboard',
              isCompact: true,
              onPressed: _pasteFromClipboard,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _importInputController,
          maxLines: 4,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: PinTokens.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'PIN_BP_... or [ {...} ]',
            hintStyle: TextStyle(
              color: PinTokens.textMuted,
              fontSize: 12,
            ),
            filled: true,
            fillColor: PinTokens.canvasBg,
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: PinTokens.borderDefault),
            ),
          ),
          onChanged: _onImportInputChanged,
        ),
        const SizedBox(height: 12),

        // Error message
        if (_importErrorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PinTokens.accentRose.withValues(alpha: 0.12),
              borderRadius: PinTokens.radiusSm,
              border: Border.all(
                  color: PinTokens.accentRose.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: PinTokens.accentRose,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _importErrorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PinTokens.accentRose,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Success message
        if (_importSuccess) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PinTokens.accentEmerald.withValues(alpha: 0.12),
              borderRadius: PinTokens.radiusSm,
              border: Border.all(
                  color: PinTokens.accentEmerald.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: PinTokens.accentEmerald,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Import completed successfully!',
                  style: TextStyle(
                    fontSize: 12,
                    color: PinTokens.accentEmerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Preview of decoded tasks
        if (_decodeResult != null && _decodeResult!.isSuccess) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PinTokens.surfaceColumn,
                borderRadius: PinTokens.radiusMd,
                border: Border.all(color: PinTokens.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview: Found ${_decodeResult!.count} tasks',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PinTokens.accentEmerald,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _decodeResult!.tasks.length,
                      itemBuilder: (context, index) {
                        final taskMap = _decodeResult!.tasks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• ${taskMap['title'] ?? 'Untitled'} (${taskMap['status'] ?? 'backlog'})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: PinTokens.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const Spacer(),
        ],
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            PinButton.primary(
              icon: Icons.merge_rounded,
              text: 'Merge Tasks',
              onPressed: (_decodeResult?.isSuccess ?? false)
                  ? () => _executeImport(replaceAll: false)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
