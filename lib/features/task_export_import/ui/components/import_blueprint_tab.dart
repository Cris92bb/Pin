import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/lib/blueprint_codec.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import 'import_blueprint_task_list.dart';

/// Tab for importing tasks from portable Base64 blueprints or raw JSON payloads.
class ImportBlueprintTab extends ConsumerStatefulWidget {
  final VoidCallback onImportComplete;

  const ImportBlueprintTab({
    super.key,
    required this.onImportComplete,
  });

  @override
  ConsumerState<ImportBlueprintTab> createState() => _ImportBlueprintTabState();
}

class _ImportBlueprintTabState extends ConsumerState<ImportBlueprintTab> {
  late final TextEditingController _inputController;
  BlueprintDecodeResult? _decodeResult;
  final Set<int> _selectedIndices = {};
  String _destinationMode = 'original'; // 'original' | 'today' | 'backlog'
  bool _replaceAll = false;
  String? _errorMessage;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _inputController.text = data.text!;
      _onTextChanged(data.text!);
    }
  }

  void _onTextChanged(String value) {
    setState(() {
      _errorMessage = null;
      if (value.trim().isEmpty) {
        _decodeResult = null;
        _selectedIndices.clear();
      } else {
        _decodeResult = BlueprintCodec.decode(value);
        if (_decodeResult!.isSuccess) {
          _selectedIndices.clear();
          for (var i = 0; i < _decodeResult!.tasks.length; i++) {
            _selectedIndices.add(i);
          }
        } else {
          _errorMessage = _decodeResult!.errorMessage;
          _selectedIndices.clear();
        }
      }
    });
  }

  Future<void> _executeImport() async {
    if (_decodeResult == null || !_decodeResult!.isSuccess || _selectedIndices.isEmpty) {
      return;
    }

    setState(() => _isImporting = true);
    try {
      final tasksToImport = <PinTask>[];
      for (final index in _selectedIndices) {
        final taskMap = _decodeResult!.tasks[index];
        var task = PinTask.fromJson(taskMap);
        if (_destinationMode == 'today') {
          task = task.copyWith(status: TaskStatus.today);
        } else if (_destinationMode == 'backlog') {
          task = task.copyWith(status: TaskStatus.backlog);
        }
        tasksToImport.add(task);
      }

      final notifier = ref.read(taskStateProvider.notifier);
      await notifier.importTasks(tasksToImport, replaceAll: _replaceAll);

      if (mounted) {
        widget.onImportComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Import failed: ${e.toString()}';
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input bar
        Row(
          children: [
            Expanded(
              child: Text(
                'Paste Blueprint Code or JSON:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            PinButton(
              icon: Icons.paste_rounded,
              text: 'Paste Clipboard',
              isCompact: true,
              onPressed: _pasteFromClipboard,
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _inputController,
          maxLines: 3,
          style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: textPrimary),
          decoration: InputDecoration(
            hintText: 'PIN_BP_... or [ {...} ]',
            hintStyle: TextStyle(
              color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextTertiary,
              fontSize: 11,
            ),
            filled: true,
            fillColor: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
            ),
          ),
          onChanged: _onTextChanged,
        ),
        const SizedBox(height: 8),

        // Error Banner
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PinTokens.accentRose.withValues(alpha: 0.12),
              borderRadius: PinTokens.radiusSm,
              border: Border.all(color: PinTokens.accentRose.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: PinTokens.accentRose, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: PinTokens.accentRose)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Destination and Replace Controls
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Target: ', style: TextStyle(fontSize: 11, color: textSecondary)),
              const SizedBox(width: 4),
              _buildDestChip('original', 'Original Status', isDark),
              const SizedBox(width: 6),
              _buildDestChip('today', 'Force Today', isDark),
              const SizedBox(width: 6),
              _buildDestChip('backlog', 'Force Backlog', isDark),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Decoded Preview
        Expanded(
          child: ImportBlueprintTaskList(
            tasks: _decodeResult?.isSuccess == true ? _decodeResult!.tasks : const [],
            selectedIndices: _selectedIndices,
            onToggleIndex: (index, selected) {
              setState(() {
                if (selected) {
                  _selectedIndices.add(index);
                } else {
                  _selectedIndices.remove(index);
                }
              });
            },
            onToggleAll: () {
              setState(() {
                if (_selectedIndices.length == _decodeResult!.tasks.length) {
                  _selectedIndices.clear();
                } else {
                  for (var i = 0; i < _decodeResult!.tasks.length; i++) {
                    _selectedIndices.add(i);
                  }
                }
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _replaceAll,
                  activeColor: PinTokens.accentRose,
                  onChanged: (val) => setState(() => _replaceAll = val ?? false),
                ),
                Text(
                  'Replace existing pins',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
            PinButton.primary(
              icon: Icons.download_rounded,
              text: _isImporting
                  ? 'Importing...'
                  : 'Import ${_selectedIndices.length} Pins',
              onPressed: (_decodeResult?.isSuccess ?? false) && _selectedIndices.isNotEmpty && !_isImporting
                  ? _executeImport
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestChip(String mode, String label, bool isDark) {
    final isSelected = _destinationMode == mode;
    final activeBg = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final inactiveBg = isDark ? PinTokens.darkCardBg : PinTokens.surfaceColumn;
    final activeFg = isDark ? PinTokens.darkCanvasBg : Colors.white;
    final inactiveFg = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return InkWell(
      borderRadius: PinTokens.radiusSm,
      onTap: () => setState(() => _destinationMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
