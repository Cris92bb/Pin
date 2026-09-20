import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/sync/model/sync_status.dart';
import '../../../features/sync/state/sync_controller.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Card displaying the authenticated user profile and live cloud sync status.
class WearableUserProfileCard extends ConsumerWidget {
  /// The current synchronization state.
  final SyncState syncState;

  /// Creates a [WearableUserProfileCard] with [syncState].
  const WearableUserProfileCard({
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
          color: PinTokens.accentEmerald.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    PinTokens.accentEmerald.withValues(alpha: 0.2),
                backgroundImage: syncState.user?.photoURL != null
                    ? NetworkImage(syncState.user!.photoURL!)
                    : null,
                child: syncState.user?.photoURL == null
                    ? const Icon(Icons.person,
                        size: 14, color: PinTokens.accentEmerald)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncState.user?.displayName ?? 'Pin User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      syncState.user?.email ?? 'Logged In',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sync status pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PinTokens.wearableStatusBadgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (syncState.status == SyncStatus.syncing)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          PinTokens.accentEmerald),
                    ),
                  )
                else
                  Icon(
                    syncState.status == SyncStatus.synced
                        ? Icons.cloud_done_rounded
                        : syncState.status == SyncStatus.error
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_queue_rounded,
                    size: 13,
                    color: syncState.status == SyncStatus.synced
                        ? PinTokens.accentEmerald
                        : syncState.status == SyncStatus.error
                            ? PinTokens.accentRose
                            : Colors.white54,
                  ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    syncState.status == SyncStatus.syncing
                        ? 'Syncing...'
                        : syncState.status == SyncStatus.synced
                            ? 'Synced (${syncState.syncedTaskCount} pins)'
                            : syncState.status == SyncStatus.error
                                ? 'Sync error'
                                : 'Offline mode',
                    style: TextStyle(
                      color: syncState.status == SyncStatus.synced
                          ? PinTokens.accentEmerald
                          : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PinTokens.accentSage,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.sync_rounded, size: 15),
              label: const Text(
                'SYNC NOW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () {
                ref.read(syncControllerProvider.notifier).syncNow();
              },
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.logout_rounded, size: 14),
              label: const Text(
                'SIGN OUT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                ref.read(syncControllerProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
