// lib/models/app_user.dart

class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final bool isGuest;

  AppUser({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    required this.isGuest,
  });

  // Convert Firestore data → AppUser
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'],
      email: data['email'],
      photoUrl: data['photoUrl'],
      isGuest: data['isGuest'] ?? false,
    );
  }

  // Convert AppUser → Firestore
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email,
      "photoUrl": photoUrl,
      "isGuest": isGuest,
    };
  }
}
