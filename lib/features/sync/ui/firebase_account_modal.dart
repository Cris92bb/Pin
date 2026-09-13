import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../state/sync_controller.dart';

/// Modal dialog providing user authentication, Cloud Firestore dual-layer sync controls,
/// Firebase project credential configuration, and GDPR right-to-erasure.
class FirebaseAccountModal extends ConsumerStatefulWidget {
  const FirebaseAccountModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FirebaseAccountModal(),
    );
  }

  @override
  ConsumerState<FirebaseAccountModal> createState() => _FirebaseAccountModalState();
}

class _FirebaseAccountModalState extends ConsumerState<FirebaseAccountModal> {
  String? _localNotice;

  Future<void> _handleGoogleSignIn([String? email]) async {
    final controller = ref.read(syncControllerProvider.notifier);
    String chosenEmail = email ?? '';

    if (chosenEmail.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark ? PinTokens.darkCardBg : Colors.white;
      final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
      final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
      final inputBg = isDark ? PinTokens.darkCanvasBg : const Color(0xFFF9FAFB);
      final borderCol = isDark ? PinTokens.darkBorder : PinTokens.lightBorderSubtle;

      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final textCtrl = TextEditingController(text: 'cris92bb@gmail.com');
          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: PinTokens.radiusLg,
              side: BorderSide(color: borderCol),
            ),
            title: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: PinTokens.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Google Sign-In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in with your Google account. No registration or password required.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Google Email Address',
                    labelStyle: TextStyle(color: textSecondary),
                    hintText: 'e.g. user@gmail.com',
                    hintStyle: TextStyle(color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted),
                    filled: true,
                    fillColor: inputBg,
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: PinTokens.radiusSm,
                      borderSide: BorderSide(color: borderCol),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: PinTokens.radiusSm,
                      borderSide: BorderSide(color: PinTokens.primary, width: 1.5),
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
                  backgroundColor: PinTokens.primary,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusSm),
                ),
                onPressed: () => Navigator.of(ctx).pop(textCtrl.text.trim()),
                child: const Text('Sign In Instantly', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
      if (result == null || result.isEmpty) return;
      chosenEmail = result;
    }

    setState(() => _localNotice = 'Signing in with Google...');
    final success = await controller.signInWithGoogle(email: chosenEmail);
    if (mounted) {
      setState(() {
        _localNotice = success ? 'Signed in as $chosenEmail' : null;
      });
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? PinTokens.darkCardBg : Colors.white;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final borderCol = isDark ? PinTokens.darkBorder : PinTokens.lightBorderSubtle;

    final confirmed = await showDialog<bool>(
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
              shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusSm),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(syncControllerProvider.notifier).deleteAccountAndCloudData();
      if (mounted) {
        setState(() {
          _localNotice = success
              ? 'Account and cloud data erased successfully.'
              : 'Failed to erase account data.';
        });
      }
    }
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
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? PinTokens.darkCardBg : Colors.white;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkCanvasBg : const Color(0xFFF9FAFB);
    final cardBorder = isDark ? PinTokens.darkBorder : PinTokens.lightBorderSubtle;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusLg,
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: PinTokens.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: PinTokens.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cloud Sync & Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Status Banner / Notice
              if (_localNotice != null || syncState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (syncState.errorMessage != null
                            ? PinTokens.accentRose
                            : PinTokens.primary)
                        .withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: PinTokens.radiusSm,
                    border: Border.all(
                      color: syncState.errorMessage != null
                          ? PinTokens.accentRose
                          : PinTokens.primary.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    syncState.errorMessage ?? _localNotice!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: syncState.errorMessage != null
                          ? PinTokens.accentRose
                          : (isDark ? PinTokens.primary : const Color(0xFF1D4ED8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Active Profile / User Section
              if (syncState.isSignedIn) ...[
                _buildSignedInCard(
                  syncState,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                ),
              ] else ...[
                _buildGuestCard(
                  syncState,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  cardBorder: cardBorder,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInCard(
    SyncState syncState, {
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
    final user = syncState.user!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: PinTokens.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                child: Text(
                  (user.displayName?.isNotEmpty == true
                          ? user.displayName![0]
                          : user.email?.isNotEmpty == true
                              ? user.email![0]
                              : 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PinTokens.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? 'Authenticated User',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'UID: ${user.uid.substring(0, user.uid.length.clamp(0, 8))}...',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? PinTokens.accentEmerald.withValues(alpha: 0.15)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  syncState.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? PinTokens.accentEmerald : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: cardBorder),
          const SizedBox(height: 10),

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

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    backgroundColor: isDark ? PinTokens.darkCardBg : Colors.white,
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
                    backgroundColor: isDark ? PinTokens.darkCardBg : Colors.white,
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
            onPressed: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(
    SyncState syncState, {
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required Color cardBorder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? PinTokens.primary.withValues(alpha: 0.10)
                : const Color(0xFFEFF6FF),
            borderRadius: PinTokens.radiusMd,
            border: Border.all(
              color: isDark
                  ? PinTokens.primary.withValues(alpha: 0.25)
                  : const Color(0xFFBFDBFE),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.offline_pin_rounded, color: PinTokens.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline-First (Guest Mode)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All pins write instantly to local storage. Zero network latency.',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 1-Click Google Sign-In button (No registration, no password)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? PinTokens.darkPhoneFrameBg : Colors.white,
            foregroundColor: textPrimary,
            side: BorderSide(
              color: isDark ? PinTokens.darkBorder : PinTokens.lightBorderSubtle,
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusMd),
            elevation: isDark ? 0 : 0.5,
            shadowColor: Colors.black.withValues(alpha: 0.08),
          ),
          onPressed: () => _handleGoogleSignIn(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4285F4),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
