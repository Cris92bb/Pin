import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../state/sync_controller.dart';
import 'firebase_account_dialogs.dart';
import 'firebase_guest_card.dart';
import 'firebase_signed_in_card.dart';

/// Modal dialog providing user authentication, Cloud Firestore sync controls,
/// and GDPR right-to-erasure.
class FirebaseAccountModal extends ConsumerStatefulWidget {
  /// Creates a [FirebaseAccountModal].
  const FirebaseAccountModal({super.key});

  /// Displays the modal dialog.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FirebaseAccountModal(),
    );
  }

  @override
  ConsumerState<FirebaseAccountModal> createState() =>
      _FirebaseAccountModalState();
}

class _FirebaseAccountModalState extends ConsumerState<FirebaseAccountModal> {
  String? _localNotice;
  bool _isGoogleSigningIn = false;
  bool _isSubmittingEmail = false;

  Future<void> _handleGoogleSignIn() async {
    final controller = ref.read(syncControllerProvider.notifier);
    setState(() {
      _isGoogleSigningIn = true;
      _localNotice = 'Authorizing in browser via Google consent screen...';
    });
    final success = await controller.signInWithGoogleSso();
    if (mounted) {
      setState(() {
        _isGoogleSigningIn = false;
        _localNotice = success ? 'Signed in with Google successfully.' : null;
      });
    }
  }

  void _handleCancelGoogleSignIn() {
    ref.read(syncControllerProvider.notifier).cancelGoogleSso();
    if (mounted) {
      setState(() {
        _isGoogleSigningIn = false;
        _localNotice = 'Google sign-in cancelled.';
      });
    }
  }

  Future<void> _handleEmailAuthSubmit({
    required bool isSignUp,
    required String email,
    required String password,
    required String name,
    required String twoFactor,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      setState(() => _localNotice = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isSubmittingEmail = true;
      _localNotice = isSignUp ? 'Creating account...' : 'Signing in...';
    });

    final controller = ref.read(syncControllerProvider.notifier);
    bool success;
    if (isSignUp) {
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
            ? (isSignUp
                ? 'Account registered & cloud sync active.'
                : 'Signed in with Email & 2FA.')
            : null;
      });
    }
  }

  Future<void> _handleEditDisplayName(String currentName) async {
    final newName = await showEditDisplayNameDialog(
      context,
      currentName: currentName,
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
    final confirmed = await showConfirmDeleteAccountDialog(context);

    if (confirmed == true && mounted) {
      final success = await ref
          .read(syncControllerProvider.notifier)
          .deleteAccountAndCloudData();
      if (mounted) {
        setState(() {
          _localNotice = success
              ? 'Account and cloud data erased successfully.'
              : 'Failed to erase account data.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBorder = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

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
                      color: isDark
                          ? PinTokens.darkHeaderPillBg
                          : PinTokens.headerSyncBgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? PinTokens.darkHeaderPillBorder
                            : PinTokens.headerSyncBorderLight,
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: isDark
                          ? PinTokens.accentEmerald
                          : PinTokens.headerSyncFgLight,
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
                      color: isDark
                          ? PinTokens.darkTextSecondary
                          : PinTokens.lightTextTertiary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: syncState.errorMessage != null
                        ? (isDark
                            ? PinTokens.dangerBgDark
                            : PinTokens.noticeErrorBgLight)
                        : (isDark
                            ? PinTokens.darkInputBg
                            : PinTokens.lightTagBg),
                    borderRadius: PinTokens.radiusSm,
                    border: Border.all(
                      color: syncState.errorMessage != null
                          ? PinTokens.dangerBorderDark
                          : (isDark
                              ? PinTokens.darkInputBorder
                              : PinTokens.lightBorder),
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
                          : (isDark
                              ? PinTokens.accentEmerald
                              : PinTokens.lightFabBg),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Active Profile / User Section
              if (syncState.isSignedIn) ...[
                FirebaseSignedInCard(
                  syncState: syncState,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  cardBorder: cardBorder,
                  onEditDisplayName: _handleEditDisplayName,
                  onDeleteAccount: _confirmDeleteAccount,
                ),
              ] else ...[
                FirebaseGuestCard(
                  syncState: syncState,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  cardBorder: cardBorder,
                  isGoogleSigningIn: _isGoogleSigningIn,
                  onGoogleSignIn: _handleGoogleSignIn,
                  onCancelGoogleSignIn: _handleCancelGoogleSignIn,
                  onEmailAuthSubmit: _handleEmailAuthSubmit,
                  isSubmittingEmail: _isSubmittingEmail,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
