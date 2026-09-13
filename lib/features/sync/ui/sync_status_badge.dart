import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/sync_status.dart';
import '../state/sync_controller.dart';
import 'firebase_account_modal.dart';

/// Compact, tactile badge displayed in the companion header
/// indicating the current Cloud Firestore synchronization state.
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon;
    final Color iconColor;
    final String tooltip;

    switch (syncState.status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_rounded;
        iconColor = isDark ? PinTokens.darkActionSyncFg : PinTokens.headerSyncFgLight;
        tooltip = 'Cloud Synced (${syncState.syncedTaskCount} pins)';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        iconColor = isDark ? PinTokens.darkActionSyncFg : PinTokens.headerSyncFgLight;
        tooltip = 'Syncing with Firestore...';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_rounded;
        iconColor = isDark ? PinTokens.darkTextMuted : const Color(0xFF64748B);
        tooltip = 'Offline - Local storage active';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_sync_outlined;
        iconColor = PinTokens.accentRose;
        tooltip = syncState.errorMessage ?? 'Sync Error - Tap to resolve';
        break;
      case SyncStatus.guest:
        icon = Icons.cloud_queue_rounded;
        iconColor = isDark ? PinTokens.darkActionSyncFg : PinTokens.headerSyncFgLight;
        tooltip = 'Guest Mode (Local Storage Only) - Tap to sync';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => FirebaseAccountModal.show(context),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? PinTokens.darkActionSyncBg : PinTokens.headerSyncBgLight,
            border: Border.all(
              color: isDark ? PinTokens.darkBorder : PinTokens.headerSyncBorderLight,
              width: 1.0,
            ),
          ),
          child: Center(
            child: syncState.status == SyncStatus.syncing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? PinTokens.darkActionSyncFg : PinTokens.primary,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: iconColor,
                  ),
          ),
        ),
      ),
    );
  }
}
