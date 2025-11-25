// lib/services/user_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;

  bool get isGuest => _user?.isGuest ?? true;
  bool get isLoggedIn => _user != null && !_user!.isGuest;

  Future<void> loadUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid);

    final doc = await ref.get();

    if (doc.exists) {
      // Load stored profile
      _user = AppUser.fromFirestore(doc.data()!, firebaseUser.uid);
    } else {
      // First-time login → create profile
      final newUser = AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName,
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
        isGuest: firebaseUser.isAnonymous,
      );

      await ref.set(newUser.toMap());

      _user = newUser;
    }

    notifyListeners();
  }
}
