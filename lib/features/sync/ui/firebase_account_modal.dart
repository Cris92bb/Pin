import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/app_user.dart';
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

  // Hidden Email & 2FA state
  bool _showEmailAuth = false;
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _isSubmittingEmail = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _twoFaCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _twoFaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final controller = ref.read(syncControllerProvider.notifier);
    setState(() => _localNotice = 'Opening browser for Google SSO...');
    final success = await controller.signInWithGoogleSso();
    if (mounted) {
      setState(() {
        _localNotice = success ? 'Signed in with Google successfully.' : null;
      });
    }
  }

  Future<void> _handleEmailAuthSubmit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final twoFactor = _twoFaCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localNotice = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isSubmittingEmail = true;
      _localNotice = _isSignUpMode ? 'Creating account...' : 'Signing in...';
    });

    final controller = ref.read(syncControllerProvider.notifier);
    bool success;
    if (_isSignUpMode) {
      success = await controller.signUpWithEmail(
        email,
        password,
        displayName: name.isNotEmpty ? name : null,
        twoFactorCode: twoFactor.isNotEmpty ? twoFactor : null,
      );
    } else {
      success = await controller.signInWithEmail(
        email,
        password,
        twoFactorCode: twoFactor.isNotEmpty ? twoFactor : null,
      );
    }

    if (mounted) {
      setState(() {
        _isSubmittingEmail = false;
        _localNotice = success
            ? (_isSignUpMode ? 'Account registered & cloud sync active.' : 'Signed in with Email & 2FA.')
            : null;
      });
    }
  }

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

  Future<void> _handleEditDisplayName(String currentName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final inputBg = isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg;
    final borderCol = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

    final nameCtrl = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: PinTokens.radiusLg,
          side: BorderSide(color: borderCol),
        ),
        title: Text('Edit Real Name', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your real name to display on your Pin companion profile.', style: TextStyle(color: textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: textSecondary),
                hintText: 'e.g. Cristian',
                hintStyle: TextStyle(color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted),
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
                    color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg,
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
              backgroundColor: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusSm),
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

    if (newName != null && newName.isNotEmpty && mounted) {
      await ref.read(syncControllerProvider.notifier).updateDisplayName(newName);
      if (mounted) {
        setState(() {
          _localNotice = 'Updated name to $newName';
        });
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final borderCol = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;

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

    final bgColor = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBorder = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: PinTokens.radiusDeck,
        side: BorderSide(color: borderColor, width: isDark ? 1.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF11221A) : PinTokens.headerSyncBgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F3D2E) : PinTokens.headerSyncBorderLight,
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: isDark ? PinTokens.accentEmerald : PinTokens.headerSyncFgLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cloud Sync & Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextTertiary,
                      size: 20,
                    ),
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
                    color: syncState.errorMessage != null
                        ? (isDark ? PinTokens.accentRose.withValues(alpha: 0.12) : const Color(0xFFFDF2F2))
                        : (isDark ? const Color(0xFF1B2520) : PinTokens.lightTagBg),
                    borderRadius: PinTokens.radiusSm,
                    border: Border.all(
                      color: syncState.errorMessage != null
                          ? PinTokens.accentRose.withValues(alpha: 0.4)
                          : (isDark ? const Color(0xFF2E4536) : PinTokens.lightBorder),
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
                          : (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg),
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
    required Color cardBorder,
  }) {
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
            _buildUserAvatar(user),
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
                        onTap: () => _handleEditDisplayName(realName),
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
                  color: isDark ? const Color(0xFF1F3D2E) : const Color(0xFFA7D7BE),
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
          onPressed: _confirmDeleteAccount,
        ),
      ],
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
                ? PinTokens.darkPhoneFrameBg
                : PinTokens.lightTagBg,
            borderRadius: PinTokens.radiusMd,
            border: Border.all(
              color: isDark
                  ? PinTokens.darkBorder
                  : PinTokens.lightBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.offline_pin_rounded,
                color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                size: 20,
              ),
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
            backgroundColor: isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCanvasBg,
            foregroundColor: textPrimary,
            side: BorderSide(
              color: isDark ? PinTokens.darkBorder : PinTokens.lightBorder,
              width: 1.0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusMd),
            elevation: 0,
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

        const SizedBox(height: 12),

        // Hidden Email & 2FA Option (Discreet collapsible accordion)
        _buildHiddenEmail2FaSection(
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          cardBorder: cardBorder,
        ),
      ],
    );
  }

  Widget _buildHiddenEmail2FaSection({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required Color cardBorder,
  }) {
    final inputBg = isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg;
    final accentCol = isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Discreet Toggle Row
        InkWell(
          onTap: () => setState(() => _showEmailAuth = !_showEmailAuth),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: textSecondary.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _showEmailAuth ? 'Hide Email & 2FA' : 'Email & 2FA Options',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showEmailAuth ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 15,
                  color: textSecondary.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),

        if (_showEmailAuth) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101713) : PinTokens.lightTagBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode switcher (Sign In vs Register)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSignUpMode = false),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isSignUpMode
                                ? (isDark ? PinTokens.darkCardBg : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: !_isSignUpMode ? cardBorder : Colors.transparent,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: !_isSignUpMode ? FontWeight.bold : FontWeight.normal,
                              color: !_isSignUpMode ? textPrimary : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSignUpMode = true),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _isSignUpMode
                                ? (isDark ? PinTokens.darkCardBg : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isSignUpMode ? cardBorder : Colors.transparent,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _isSignUpMode ? FontWeight.bold : FontWeight.normal,
                              color: _isSignUpMode ? textPrimary : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_isSignUpMode) ...[
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(fontSize: 12, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Display Name (optional)',
                      hintStyle: TextStyle(fontSize: 11, color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted),
                      prefixIcon: Icon(Icons.badge_outlined, size: 16, color: textSecondary),
                      filled: true,
                      fillColor: inputBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: accentCol, width: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 12, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(fontSize: 11, color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted),
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 16, color: textSecondary),
                    filled: true,
                    fillColor: inputBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: accentCol, width: 1.2)),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: 12, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(fontSize: 11, color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted),
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 16,
                        color: textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: inputBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: accentCol, width: 1.2)),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _twoFaCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(fontSize: 12, color: textPrimary, letterSpacing: 2.0),
                  decoration: InputDecoration(
                    hintText: '2FA Code / PIN (optional)',
                    hintStyle: TextStyle(fontSize: 11, color: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted, letterSpacing: 0),
                    prefixIcon: Icon(Icons.security_rounded, size: 16, color: textSecondary),
                    counterText: '',
                    filled: true,
                    fillColor: inputBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: PinTokens.radiusSm, borderSide: BorderSide(color: accentCol, width: 1.2)),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentCol,
                    foregroundColor: isDark ? PinTokens.darkPhoneFrameBg : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusSm),
                  ),
                  onPressed: _isSubmittingEmail ? null : _handleEmailAuthSubmit,
                  child: _isSubmittingEmail
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? PinTokens.darkPhoneFrameBg : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isSignUpMode ? 'Register & Enable 2FA' : 'Sign In with 2FA',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserAvatar(AppUser user) {
    final photoURL = user.photoURL;
    final hasPhoto = photoURL != null && photoURL.trim().isNotEmpty;

    Widget googleGBadge() {
      return Container(
        width: 40,
        height: 40,
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
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          photoURL,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => googleGBadge(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return googleGBadge();
          },
        ),
      );
    }

    return googleGBadge();
  }
}
