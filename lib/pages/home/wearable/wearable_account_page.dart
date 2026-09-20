import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/sync/state/sync_controller.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wearable_account_cards.dart';

/// The Account page of the Wear OS carousel view.
///
/// Displays cloud sync state, user profile, Google authentication,
/// and manual sync triggers.
class WearableAccountPage extends ConsumerWidget {
  /// Current synchronization state.
  final SyncState syncState;

  /// Safe circular insets to prevent clipping on round watch faces.
  final EdgeInsets safePadding;

  /// Creates a [WearableAccountPage] with [syncState] and [safePadding].
  const WearableAccountPage({
    super.key,
    required this.syncState,
    required this.safePadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = !syncState.isSignedIn;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: safePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isGuest
                      ? Colors.white.withValues(alpha: 0.1)
                      : PinTokens.accentEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGuest
                        ? Colors.white.withValues(alpha: 0.2)
                        : PinTokens.accentEmerald.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  isGuest ? 'ACCOUNT (GUEST)' : 'ACCOUNT',
                  style: TextStyle(
                    color:
                        isGuest ? Colors.white70 : PinTokens.accentEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isGuest)
            WearableGuestAccountCard(syncState: syncState)
          else
            WearableUserProfileCard(syncState: syncState),
          const SizedBox(height: 8),
          Text(
            'Swipe left for Today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
