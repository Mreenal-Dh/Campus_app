// lib/services/saved_places_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_place.dart';

class SavedPlacesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection: users/{uid}/saved_places/{placeId}
  CollectionReference<Map<String, dynamic>> _userSavedRef(String uid) =>
      _db.collection('users').doc(uid).collection('saved_places');

  Future<void> savePlace({
    required String uid,
    required SavedPlace place,
  }) async {
    await _userSavedRef(uid).doc(place.id).set(place.toMap());
  }

  Future<void> unsavePlace({
    required String uid,
    required String placeId,
  }) async {
    await _userSavedRef(uid).doc(placeId).delete();
  }

  Future<bool> isSaved({
    required String uid,
    required String placeId,
  }) async {
    final doc = await _userSavedRef(uid).doc(placeId).get();
    return doc.exists;
  }

  Stream<bool> isSavedStream({
    required String uid,
    required String placeId,
  }) {
    return _userSavedRef(uid).doc(placeId).snapshots().map((doc) => doc.exists);
  }

  Stream<List<SavedPlace>> savedPlacesStream({required String uid}) {
    return _userSavedRef(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SavedPlace.fromDoc(d.id, d.data())).toList());
  }

  Future<List<SavedPlace>> getSavedPlacesOnce({required String uid}) async {
    final snap =
        await _userSavedRef(uid).orderBy('timestamp', descending: true).get();

    return snap.docs.map((d) => SavedPlace.fromDoc(d.id, d.data())).toList();
  }
}
