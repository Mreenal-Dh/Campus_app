// lib/models/place_models.dart
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradientColors,
    required this.subcategories,
  });

  // convenience factory for quick local creation
  factory Category.local({
    required String id,
    required String name,
    required IconData icon,
    required List<Color> gradientColors,
    required List<String> subcategories,
  }) =>
      Category(
        id: id,
        name: name,
        icon: icon,
        gradientColors: gradientColors,
        subcategories: subcategories,
      );
}

class Place {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String imageUrl;
  final double? lat;
  final double? lng;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.imageUrl,
    this.lat,
    this.lng,
  });
}
