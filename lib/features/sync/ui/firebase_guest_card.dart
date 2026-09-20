import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../state/sync_controller.dart';
import 'firebase_email_auth_form.dart';

/// Card displayed when the user is unauthenticated, offering Google SSO and Email/2FA.
class FirebaseGuestCard extends StatefulWidget {
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

  /// Whether Google Sign-In is in flight.
  final bool isGoogleSigningIn;

  /// Callback to initiate Google Sign-In.
  final VoidCallback onGoogleSignIn;

  /// Callback to cancel pending Google Sign-In.
  final VoidCallback onCancelGoogleSignIn;

  /// Callback for Email/2FA submission.
  final Future<void> Function({
    required bool isSignUp,
    required String email,
    required String password,
    required String name,
    required String twoFactor,
  }) onEmailAuthSubmit;

  /// Whether email authentication submission is in flight.
  final bool isSubmittingEmail;

  /// Creates a [FirebaseGuestCard].
  const FirebaseGuestCard({
    super.key,
    required this.syncState,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.cardBorder,
    required this.isGoogleSigningIn,
    required this.onGoogleSignIn,
    required this.onCancelGoogleSignIn,
    required this.onEmailAuthSubmit,
    required this.isSubmittingEmail,
  });

  @override
  State<FirebaseGuestCard> createState() => _FirebaseGuestCardState();
}

class _FirebaseGuestCardState extends State<FirebaseGuestCard> {
  bool _showEmailAuth = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? PinTokens.darkPhoneFrameBg
                : PinTokens.lightTagBg,
            borderRadius: PinTokens.radiusMd,
            border: Border.all(
              color: widget.isDark
                  ? PinTokens.darkBorder
                  : PinTokens.lightBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.offline_pin_rounded,
                color: widget.isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
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
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All pins write instantly to local storage. Zero network latency.',
                      style: TextStyle(fontSize: 11, color: widget.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 1-Click Google Sign-In button (Direct OAuth consent screen)
        if (widget.isGoogleSigningIn) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCanvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(
                color: widget.isDark
                    ? PinTokens.accentEmerald.withValues(alpha: 0.5)
                    : PinTokens.lightFabBg,
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(PinTokens.accentEmerald),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Waiting for Google in browser...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: widget.onCancelGoogleSignIn,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text(
                    'Cancel Sign-In',
                    style: TextStyle(
                      fontSize: 11,
                      color: PinTokens.accentRose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCanvasBg,
              foregroundColor: widget.textPrimary,
              side: BorderSide(
                color: widget.isDark ? PinTokens.darkBorder : PinTokens.lightBorder,
                width: 1.0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: const RoundedRectangleBorder(borderRadius: PinTokens.radiusMd),
              elevation: 0,
            ),
            onPressed: widget.onGoogleSignIn,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: PinTokens.googleBlue,
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

        const SizedBox(height: 12),

        // Hidden Email & 2FA Option (Discreet collapsible accordion)
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
                  color: widget.textSecondary.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _showEmailAuth ? 'Hide Email & 2FA' : 'Email & 2FA Options',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.textSecondary.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showEmailAuth ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 15,
                  color: widget.textSecondary.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),

        if (_showEmailAuth) ...[
          const SizedBox(height: 8),
          FirebaseEmailAuthForm(
            isDark: widget.isDark,
            cardBorder: widget.cardBorder,
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            isSubmitting: widget.isSubmittingEmail,
            onSubmit: widget.onEmailAuthSubmit,
          ),
        ],
      ],
    );
  }
}
