import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/sync/state/sync_controller.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Modal dialog for performing email authentication on a Wear OS smartwatch.
Future<void> showWatchEmailSignIn(
  BuildContext context,
  WidgetRef ref, {
  String? prefillEmail,
  String? hintMessage,
}) async {
  final controller = ref.read(syncControllerProvider.notifier);
  final emailCtrl = TextEditingController(text: prefillEmail ?? '');
  final passCtrl = TextEditingController();
  final twoFaCtrl = TextEditingController();
  final hasPrefill = prefillEmail != null && prefillEmail.trim().isNotEmpty;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: PinTokens.wearableCardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PinTokens.accentSage, width: 1.2),
      ),
      titlePadding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      actionsPadding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, color: PinTokens.accentSage, size: 16),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'Email & 2FA',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hintMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PinTokens.accentSage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hintMessage,
                style: const TextStyle(
                  color: PinTokens.accentSage,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            autofocus: !hasPrefill,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              filled: true,
              fillColor: PinTokens.wearableCardSurface,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PinTokens.accentSage),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: passCtrl,
            obscureText: true,
            autofocus: hasPrefill,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              filled: true,
              fillColor: PinTokens.wearableCardSurface,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PinTokens.accentSage),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: twoFaCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, letterSpacing: 1.5),
            decoration: InputDecoration(
              hintText: '2FA PIN (optional)',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  letterSpacing: 0),
              counterText: '',
              filled: true,
              fillColor: PinTokens.wearableCardSurface,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: PinTokens.accentSage),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCEL',
                    style: TextStyle(fontSize: 10, color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PinTokens.accentSage,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await controller.signInWithEmail(
                    emailCtrl.text.trim(),
                    passCtrl.text.trim(),
                    twoFactorCode: twoFaCtrl.text.trim().isNotEmpty
                        ? twoFaCtrl.text.trim()
                        : null,
                  );
                },
                child: const Text('SIGN IN',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
