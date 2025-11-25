// lib/models/saved_place.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPlace {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final String imageUrl;
  final Timestamp timestamp;

  SavedPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "category": category,
      "subcategory": subcategory,
      "imageUrl": imageUrl,
      "timestamp": timestamp,
    };
  }

  static SavedPlace fromDoc(String id, Map<String, dynamic> map) {
    return SavedPlace(
      id: id,
      name: map["name"] ?? "",
      category: map["category"] ?? "",
      subcategory: map["subcategory"] ?? "",
      imageUrl: map["imageUrl"] ?? "",
      timestamp: map["timestamp"] ?? Timestamp.now(),
    );
  }
}
