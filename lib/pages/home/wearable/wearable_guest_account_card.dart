import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/sync/state/sync_controller.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wearable_auth_dialogs.dart';

/// Card shown when the user is operating in guest (unauthenticated) mode.
class WearableGuestAccountCard extends ConsumerWidget {
  /// The current synchronization state.
  final SyncState syncState;

  /// Creates a [WearableGuestAccountCard] with [syncState].
  const WearableGuestAccountCard({
    super.key,
    required this.syncState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PinTokens.wearableCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PinTokens.accentSage.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_queue_rounded,
            size: 26,
            color: PinTokens.accentSage,
          ),
          const SizedBox(height: 4),
          const Text(
            'Cloud Sync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sign in to sync your pins across phone, web & watch.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          if (syncState.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              syncState.errorMessage!,
              style: const TextStyle(
                color: PinTokens.accentRose,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PinTokens.accentSage,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.account_circle_outlined, size: 16),
              label: const Text(
                'GOOGLE SIGN-IN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              onPressed: () => showWatchGoogleSignIn(context, ref),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 15),
              label: const Text(
                'EMAIL SIGN-IN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => showWatchEmailSignIn(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
