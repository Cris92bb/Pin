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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late TextEditingController _apiKeyController;
  late TextEditingController _projectIdController;
  late TextEditingController _databaseIdController;

  bool _isSignUpMode = false;
  bool _showConfigSection = false;
  String? _localNotice;

  @override
  void initState() {
    super.initState();
    final config = ref.read(syncControllerProvider).config;
    _apiKeyController = TextEditingController(text: config.apiKey);
    _projectIdController = TextEditingController(text: config.projectId);
    _databaseIdController = TextEditingController(text: config.firestoreDatabaseId);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _apiKeyController.dispose();
    _projectIdController.dispose();
    _databaseIdController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthSubmit() async {
    final controller = ref.read(syncControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localNotice = 'Please enter both email and password.');
      return;
    }

    setState(() => _localNotice = null);

    final bool success;
    if (_isSignUpMode) {
      final name = _nameController.text.trim();
      success = await controller.signUpWithEmail(
        email,
        password,
        displayName: name.isNotEmpty ? name : null,
      );
    } else {
      success = await controller.signInWithEmail(email, password);
    }

    if (success && mounted) {
      setState(() {
        _localNotice = 'Successfully authenticated!';
      });
    }
  }

  Future<void> _handleSaveConfig() async {
    final controller = ref.read(syncControllerProvider.notifier);
    final currentConfig = ref.read(syncControllerProvider).config;

    final newConfig = currentConfig.copyWith(
      apiKey: _apiKeyController.text.trim(),
      projectId: _projectIdController.text.trim(),
      firestoreDatabaseId: _databaseIdController.text.trim().isEmpty
          ? '(default)'
          : _databaseIdController.text.trim(),
    );

    await controller.updateConfig(newConfig);
    if (mounted) {
      setState(() {
        _localNotice = 'Firebase configuration saved!';
      });
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account & Cloud Data?'),
        content: const Text(
          'This will permanently delete your Cloud Firestore board document (/users/{userId}/meta/board) '
          'and erase your Firebase authentication account under GDPR Right-to-Erasure regulations. '
          'Your local offline data will remain untouched on this machine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PinTokens.accentRose),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
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
                  const Icon(Icons.cloud_sync_rounded, color: PinTokens.primary, size: 24),
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
                        .withValues(alpha: 0.12),
                    borderRadius: PinTokens.radiusSm,
                    border: Border.all(
                      color: syncState.errorMessage != null
                          ? PinTokens.accentRose
                          : PinTokens.primary,
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
                          : PinTokens.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Active Profile / User Section
              if (syncState.isSignedIn) ...[
                _buildSignedInCard(syncState, textPrimary, textSecondary, isDark, borderColor),
              ] else ...[
                _buildGuestCard(syncState, textPrimary, textSecondary, isDark, borderColor),
              ],

              const SizedBox(height: 16),

              // Firebase Project Configuration Accordion
              InkWell(
                onTap: () => setState(() => _showConfigSection = !_showConfigSection),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Firebase Project Settings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        _showConfigSection
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              if (_showConfigSection) ...[
                const SizedBox(height: 8),
                _buildConfigSection(textPrimary, textSecondary, isDark, borderColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInCard(
    SyncState syncState,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    Color borderColor,
  ) {
    final user = syncState.user!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: PinTokens.primary.withValues(alpha: 0.15),
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
                  color: PinTokens.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  syncState.status.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: PinTokens.accentEmerald,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
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
          const SizedBox(height: 4),
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
                  onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign Out'),
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
              style: TextStyle(color: PinTokens.accentRose, fontSize: 11),
            ),
            onPressed: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(
    SyncState syncState,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PinTokens.primary.withValues(alpha: 0.08),
            borderRadius: PinTokens.radiusMd,
            border: Border.all(color: PinTokens.primary.withValues(alpha: 0.2)),
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

        // Auth mode switch
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isSignUpMode = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: !_isSignUpMode ? PinTokens.primary : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: !_isSignUpMode ? FontWeight.bold : FontWeight.normal,
                        color: !_isSignUpMode ? PinTokens.primary : textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isSignUpMode = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _isSignUpMode ? PinTokens.primary : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: _isSignUpMode ? FontWeight.bold : FontWeight.normal,
                        color: _isSignUpMode ? PinTokens.primary : textSecondary,
                      ),
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name (optional)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: PinTokens.radiusSm),
            ),
          ),
          const SizedBox(height: 8),
        ],

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            isDense: true,
            border: OutlineInputBorder(borderRadius: PinTokens.radiusSm),
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            isDense: true,
            border: OutlineInputBorder(borderRadius: PinTokens.radiusSm),
          ),
        ),

        const SizedBox(height: 12),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PinTokens.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _handleAuthSubmit,
          child: Text(
            _isSignUpMode ? 'Create Cloud Account' : 'Sign In to Cloud Sync',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),

        const SizedBox(height: 8),

        OutlinedButton(
          onPressed: () => ref.read(syncControllerProvider.notifier).signInAnonymously(),
          child: const Text('One-Click Demo Sign-In'),
        ),
      ],
    );
  }

  Widget _buildConfigSection(
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connect your Firebase Project',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stores board snapshot under /users/{userId}/meta/board with 1,000ms debounce.',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Firebase API Key',
              isDense: true,
              border: OutlineInputBorder(borderRadius: PinTokens.radiusSm),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _projectIdController,
            decoration: const InputDecoration(
              labelText: 'Project ID',
              isDense: true,
              border: OutlineInputBorder(borderRadius: PinTokens.radiusSm),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _databaseIdController,
            decoration: const InputDecoration(
              labelText: 'Firestore Database ID (default: (default))',
              isDense: true,
              border: OutlineInputBorder(borderRadius: PinTokens.radiusSm),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _handleSaveConfig,
            child: const Text('Save Credentials'),
          ),
        ],
      ),
    );
  }
}
