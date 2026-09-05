/// Represents an authenticated Firebase user profile or guest user.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? idToken;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.idToken,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'isAnonymous': isAnonymous,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoURL: json['photoURL'] as String?,
        isAnonymous: json['isAnonymous'] as bool? ?? false,
      );

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? idToken,
    bool? isAnonymous,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      idToken: idToken ?? this.idToken,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
