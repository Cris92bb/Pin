import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/task_text_formatter.dart';

/// Tab for viewing and copying a single [PinTask] as a formatted Markdown text note.
class SingleTaskTextTab extends StatefulWidget {
  final PinTask task;

  const SingleTaskTextTab({super.key, required this.task});

  @override
  State<SingleTaskTextTab> createState() => _SingleTaskTextTabState();
}

class _SingleTaskTextTabState extends State<SingleTaskTextTab> {
  bool _copied = false;

  Future<void> _copyText(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final formatted = TaskTextFormatter.formatSingleTask(widget.task);

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
                formatted,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.45,
                  color: textPrimary,
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
              text: _copied ? 'Copied as Text!' : 'Copy Formatted Text',
              onPressed: () => _copyText(formatted),
            ),
          ],
        ),
      ],
    );
  }
}
