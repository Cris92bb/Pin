import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Form component for Email, password, and two-factor authentication.
class FirebaseEmailAuthForm extends StatefulWidget {
  /// Whether dark theme is active.
  final bool isDark;

  /// Card border color token.
  final Color cardBorder;

  /// Primary text color token.
  final Color textPrimary;

  /// Secondary text color token.
  final Color textSecondary;

  /// Whether a submission is currently in flight.
  final bool isSubmitting;

  /// Callback when submitting with email, password, optional name, and optional 2FA code.
  final Future<void> Function({
    required bool isSignUp,
    required String email,
    required String password,
    required String name,
    required String twoFactor,
  }) onSubmit;

  /// Creates a [FirebaseEmailAuthForm].
  const FirebaseEmailAuthForm({
    super.key,
    required this.isDark,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<FirebaseEmailAuthForm> createState() => _FirebaseEmailAuthFormState();
}

class _FirebaseEmailAuthFormState extends State<FirebaseEmailAuthForm> {
  bool _isSignUpMode = false;
  bool _obscurePassword = true;

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

  void _submit() {
    widget.onSubmit(
      isSignUp: _isSignUpMode,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      name: _nameCtrl.text.trim(),
      twoFactor: _twoFaCtrl.text.trim(),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
    double? letterSpacing,
  }) {
    final inputBg =
        widget.isDark ? PinTokens.darkCanvasBg : PinTokens.lightCanvasBg;
    final accentCol =
        widget.isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 11,
        color: widget.isDark
            ? PinTokens.darkTextMuted
            : PinTokens.lightTextMuted,
        letterSpacing: letterSpacing != null ? 0 : null,
      ),
      prefixIcon: Icon(icon, size: 16, color: widget.textSecondary),
      suffixIcon: suffixIcon,
      counterText: '',
      filled: true,
      fillColor: inputBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: PinTokens.radiusSm,
        borderSide: BorderSide(color: widget.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PinTokens.radiusSm,
        borderSide: BorderSide(color: widget.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PinTokens.radiusSm,
        borderSide: BorderSide(color: accentCol, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentCol =
        widget.isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? PinTokens.darkAccountTileBg
            : PinTokens.lightTagBg,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(color: widget.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode switcher (Sign In vs Register)
          Row(
            children: [
              Expanded(
                child: _buildModeTab(
                  label: 'Sign In',
                  isActive: !_isSignUpMode,
                  onTap: () => setState(() => _isSignUpMode = false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildModeTab(
                  label: 'Register',
                  isActive: _isSignUpMode,
                  onTap: () => setState(() => _isSignUpMode = true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_isSignUpMode) ...[
            TextField(
              controller: _nameCtrl,
              style: TextStyle(fontSize: 12, color: widget.textPrimary),
              decoration: _buildInputDecoration(
                hintText: 'Display Name (optional)',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 8),
          ],

          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 12, color: widget.textPrimary),
            decoration: _buildInputDecoration(
              hintText: 'Email address',
              icon: Icons.mail_outline_rounded,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: 12, color: widget.textPrimary),
            decoration: _buildInputDecoration(
              hintText: 'Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: widget.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _twoFaCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              fontSize: 12,
              color: widget.textPrimary,
              letterSpacing: 2.0,
            ),
            decoration: _buildInputDecoration(
              hintText: '2FA Code / PIN (optional)',
              icon: Icons.security_rounded,
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentCol,
              foregroundColor:
                  widget.isDark ? PinTokens.darkPhoneFrameBg : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: const RoundedRectangleBorder(
                borderRadius: PinTokens.radiusSm,
              ),
            ),
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isDark
                            ? PinTokens.darkPhoneFrameBg
                            : Colors.white,
                      ),
                    ),
                  )
                : Text(
                    _isSignUpMode
                        ? 'Register & Enable 2FA'
                        : 'Sign In with 2FA',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (widget.isDark ? PinTokens.darkCardBg : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? widget.cardBorder : Colors.transparent,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? widget.textPrimary : widget.textSecondary,
          ),
        ),
      ),
    );
  }
}
