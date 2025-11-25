// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Restrict Google sign-in to college domain
  static const allowedDomain = "iiitnr.edu.in";

  /// Configure Google Sign-In with domain hint
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    hostedDomain: allowedDomain, // not enforced by Google, but helps
    scopes: ['email'],
  );

  /// STREAM → tells the app when user logs in / logs out
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Returns the current Firebase user
  User? get currentUser => _auth.currentUser;

  /// GUEST MODE login
  Future<void> signInAsGuest() async {
    await _auth.signInAnonymously();
  }

  /// GOOGLE LOGIN with domain restriction
  Future<String?> signInWithGoogle() async {
    try {
      // Start Google login
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) return "Login cancelled";

      final email = gUser.email;

      // 🔥 HARD DOMAIN RESTRICTION (client-side)
      if (!email.endsWith("@$allowedDomain")) {
        // force logout from Google provider
        await _googleSignIn.signOut();
        return "Only IIITNR email IDs are allowed.";
      }

      // Authenticate with Firebase
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null; // success
    } catch (e) {
      print("Google Sign-In Failed: $e");
      return "Google login failed. Try again.";
    }
  }

  /// SIGN OUT
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Is user guest?
  bool get isGuest {
    final user = _auth.currentUser;
    return user != null && user.isAnonymous;
  }
}

