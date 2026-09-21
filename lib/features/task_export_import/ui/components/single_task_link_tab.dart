import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/deep_link_service.dart';

/// Tab for generating and copying an instant deep link for a single [PinTask].
class SingleTaskLinkTab extends StatefulWidget {
  final PinTask task;

  const SingleTaskLinkTab({super.key, required this.task});

  @override
  State<SingleTaskLinkTab> createState() => _SingleTaskLinkTabState();
}

class _SingleTaskLinkTabState extends State<SingleTaskLinkTab> {
  bool _copied = false;

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
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
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final link = DeepLinkService.generateShareLink(widget.task);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shareable Deep Link:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    link,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: PinTokens.accentEmerald,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? PinTokens.darkCardBg : PinTokens.surfaceColumn,
                      borderRadius: PinTokens.radiusSm,
                      border: Border.all(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: PinTokens.accentEmerald),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tapping this link in WhatsApp, Telegram, email, or a browser will open the Pin app and prompt to import this pin.',
                            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton.primary(
              icon: _copied ? Icons.check_rounded : Icons.link_rounded,
              text: _copied ? 'Copied Link!' : 'Copy Share Link',
              onPressed: () => _copyLink(link),
            ),
          ],
        ),
      ],
    );
  }
}
