import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/sync/state/sync_controller.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Modal dialog for performing Google Sign-In on a Wear OS smartwatch.
Future<void> showWatchGoogleSignIn(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(syncControllerProvider.notifier);

  await showDialog(
    context: context,
    builder: (ctx) {
      bool isConnecting = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: PinTokens.wearableCardBg,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: PinTokens.accentSage, width: 1.2),
            ),
            titlePadding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            actionsPadding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined,
                    color: PinTokens.accentSage, size: 16),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Google Sign-In',
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
                if (isConnecting) ...[
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PinTokens.accentSage,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connecting to companion phone...',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ] else if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                        color: PinTokens.accentRose, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'Sign in on your paired phone to automatically sync your pins.',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap below to connect.',
                    style: TextStyle(color: Colors.white38, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            actions: [
              if (!isConnecting) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('CANCEL',
                            style: TextStyle(
                                fontSize: 10, color: Colors.white54)),
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
                          setDialogState(() {
                            isConnecting = true;
                            errorMessage = null;
                          });
                          final result =
                              await controller.signInWithCompanionPhone();
                          if (!dialogCtx.mounted) return;
                          if (result.success) {
                            Navigator.of(dialogCtx).pop();
                          } else {
                            setDialogState(() {
                              isConnecting = false;
                              errorMessage =
                                  result.errorMessage ?? 'Sign-in failed.';
                            });
                          }
                        },
                        child: const Text('SIGN IN',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      );
    },
  );
}
