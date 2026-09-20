import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/app_user.dart';
import '../state/sync_controller.dart';
import 'firebase_user_avatar.dart';

/// Card displayed when user is authenticated, showing profile, sync controls, and GDPR options.
class FirebaseSignedInCard extends ConsumerWidget {
  /// The current sync state.
  final SyncState syncState;

  /// Primary text color token.
  final Color textPrimary;

  /// Secondary text color token.
  final Color textSecondary;

  /// Whether dark mode is active.
  final bool isDark;

  /// Card border color token.
  final Color cardBorder;

  /// Callback when user requests editing their display name.
  final Future<void> Function(String currentName) onEditDisplayName;

  /// Callback when user confirms permanent deletion of account and cloud data.
  final Future<void> Function() onDeleteAccount;

  /// Creates a [FirebaseSignedInCard].
  const FirebaseSignedInCard({
    super.key,
    required this.syncState,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.cardBorder,
    required this.onEditDisplayName,
    required this.onDeleteAccount,
  });

  String _getRealDisplayName(AppUser user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      final name = user.displayName!.trim();
      if (name.toLowerCase() == 'cristun92xd') {
        return 'Cristian';
      }
      if (name.contains('.') || name.contains('_')) {
        final formatted = name
            .split(RegExp(r'[._]'))
            .where((s) => s.isNotEmpty)
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' ');
        if (formatted.isNotEmpty) return formatted;
      }
      return name;
    }
    if (user.email != null && user.email!.contains('@')) {
      final prefix = user.email!.split('@').first.trim();
      if (prefix.isEmpty) return 'User';
      if (prefix.toLowerCase() == 'cristun92xd') {
        return 'Cristian';
      }
      if (prefix.contains('.') || prefix.contains('_')) {
        final formatted = prefix
            .split(RegExp(r'[._]'))
            .where((s) => s.isNotEmpty)
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' ');
        if (formatted.isNotEmpty) return formatted;
      }
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
    return 'User';
  }

  String _formatTimestamp(int? millis) {
    if (millis == null) return 'Never';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(millis));
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = syncState.user!;
    final realName = _getRealDisplayName(user);
    final userSubtext = user.email != null && user.email!.isNotEmpty
        ? user.email!
        : 'UID: ${user.uid.substring(0, user.uid.length.clamp(0, 8))}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FirebaseUserAvatar(user: user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          realName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => onEditDisplayName(realName),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    userSubtext,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? PinTokens.accentEmerald.withValues(alpha: 0.15)
                    : PinTokens.energyLowBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? PinTokens.darkHeaderPillBorder : PinTokens.headerSyncBorderMedium,
                  width: 1.0,
                ),
              ),
              child: Text(
                syncState.status.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? PinTokens.accentEmerald : PinTokens.energyLowText,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        Divider(height: 1, color: cardBorder),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Last Synced:',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            Text(
              _formatTimestamp(syncState.lastSyncedAt),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Synced Pins:',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            Text(
              '${syncState.syncedTaskCount} pins',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightTagBg,
                  side: BorderSide(color: cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  backgroundColor: isDark ? PinTokens.darkCardBg : PinTokens.lightTagBg,
                  side: BorderSide(color: cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => ref.read(syncControllerProvider.notifier).signOut(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        TextButton.icon(
          icon: const Icon(Icons.delete_forever_rounded, size: 16, color: PinTokens.accentRose),
          label: const Text(
            'Delete Account & Cloud Data (GDPR)',
            style: TextStyle(color: PinTokens.accentRose, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onPressed: onDeleteAccount,
        ),
      ],
    );
  }
}
