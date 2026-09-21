import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin/shared/lib/blueprint_codec.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Tab for copying a single [PinTask] encoded as a portable blueprint string.
class SingleTaskBlueprintTab extends StatefulWidget {
  final PinTask task;

  const SingleTaskBlueprintTab({super.key, required this.task});

  @override
  State<SingleTaskBlueprintTab> createState() => _SingleTaskBlueprintTabState();
}

class _SingleTaskBlueprintTabState extends State<SingleTaskBlueprintTab> {
  bool _copied = false;

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final code = BlueprintCodec.encodeSingleTask(widget.task.toJson());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(
                color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: PinTokens.accentEmerald,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton.primary(
              icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
              text: _copied ? 'Copied Code!' : 'Copy Blueprint Code',
              onPressed: () => _copyCode(code),
            ),
          ],
        ),
      ],
    );
  }
}
