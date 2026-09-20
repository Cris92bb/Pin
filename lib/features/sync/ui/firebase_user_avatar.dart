import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/app_user.dart';

/// Renders a circular user avatar with Google branding fallback.
class FirebaseUserAvatar extends StatelessWidget {
  /// The user whose photo or monogram to display.
  final AppUser user;

  /// Creates a [FirebaseUserAvatar] with [user].
  const FirebaseUserAvatar({super.key, required this.user});

  Widget _buildGoogleBadge() {
    return Container(
      width: 40,
      height: 40,
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
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = user.photoURL;
    final hasPhoto = photoURL != null && photoURL.trim().isNotEmpty;

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          photoURL,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildGoogleBadge(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildGoogleBadge();
          },
        ),
      );
    }

    return _buildGoogleBadge();
  }
}
