/// Represents an authenticated Firebase user profile or guest user.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? idToken;

  /// Firebase refresh token — used to obtain a new [idToken] when it expires.
  final String? refreshToken;

  /// Unix milliseconds when [idToken] expires. Firebase tokens last 1 hour.
  /// Null means unknown / not yet set (assume still valid).
  final int? tokenExpiresAt;

  final bool isAnonymous;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.idToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.isAnonymous = false,
  });

  /// Returns true if the ID token is missing or within 5 minutes of expiry.
  bool get isTokenExpired {
    if (idToken == null || idToken!.isEmpty) return true;
    if (tokenExpiresAt == null) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(tokenExpiresAt!);
    return DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'idToken': idToken,
        'refreshToken': refreshToken,
        'tokenExpiresAt': tokenExpiresAt,
        'isAnonymous': isAnonymous,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoURL: json['photoURL'] as String?,
        idToken: json['idToken'] as String?,
        refreshToken: json['refreshToken'] as String?,
        tokenExpiresAt: json['tokenExpiresAt'] as int?,
        isAnonymous: json['isAnonymous'] as bool? ?? false,
      );

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? idToken,
    String? refreshToken,
    int? tokenExpiresAt,
    bool? isAnonymous,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
