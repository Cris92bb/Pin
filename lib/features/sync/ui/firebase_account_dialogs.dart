import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Shows a dialog to edit the user's real display name.
Future<String?> showEditDisplayNameDialog(
  BuildContext context, {
  required String currentName,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
  final textPrimary =
      isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
  final textSecondary =
      isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
  final inputBg = isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg;
  final borderCol = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

  final nameCtrl = TextEditingController(text: currentName);

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusLg,
        side: BorderSide(color: borderCol),
      ),
      title: Text(
        'Edit Real Name',
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your real name to display on your Pin companion profile.',
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            autofocus: true,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: textSecondary),
              hintText: 'e.g. Cristian',
              hintStyle: TextStyle(
                color: isDark
                    ? PinTokens.darkTextMuted
                    : PinTokens.lightTextMuted,
              ),
              filled: true,
              fillColor: inputBg,
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: PinTokens.radiusSm,
                borderSide: BorderSide(color: borderCol),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: PinTokens.radiusSm,
                borderSide: BorderSide(
                  color: isDark
                      ? PinTokens.darkActiveFocus
                      : PinTokens.lightFabBg,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Cancel', style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
            elevation: 0,
            shape:
                const RoundedRectangleBorder(borderRadius: PinTokens.radiusSm),
          ),
          onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()),
          child: Text(
            'Save Name',
            style: TextStyle(
              color: isDark ? PinTokens.darkPhoneFrameBg : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shows a confirmation dialog for GDPR account deletion.
Future<bool?> showConfirmDeleteAccountDialog(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
  final textPrimary =
      isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
  final textSecondary =
      isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
  final borderCol = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusLg,
        side: BorderSide(color: borderCol),
      ),
      title: Text(
        'Delete Account & Cloud Data?',
        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'This will permanently delete your Cloud Firestore board document (/users/{userId}/meta/board) '
        'and erase your Firebase authentication account under GDPR Right-to-Erasure regulations. '
        'Your local offline data will remain untouched on this machine.',
        style: TextStyle(color: textSecondary, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PinTokens.accentRose,
            elevation: 0,
            shape:
                const RoundedRectangleBorder(borderRadius: PinTokens.radiusSm),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Delete Permanently',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
