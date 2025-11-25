// lib/pages/place_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/saved_places_service.dart';
import '../services/user_provider.dart';
import '../models/saved_place.dart';
import 'place_details_page.dart';

class PlaceListPage extends StatelessWidget {
  final String categoryName;
  final String subcategoryName;

  const PlaceListPage({
    super.key,
    required this.categoryName,
    required this.subcategoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Dummy data for now
    final places = [
      {
        "id": "p1",
        "name": "Sample Place 1",
        "rating": 4.5,
        "address": "Raipur, Chhattisgarh",
        "image": "assets/sample1.jpg",
        "lat": 21.2514,
        "lng": 81.6296,
      },
      {
        "id": "p2",
        "name": "Sample Place 2",
        "rating": 4.2,
        "address": "Raipur, Chhattisgarh",
        "image": "assets/sample2.jpg",
        "lat": 21.2500,
        "lng": 81.6300,
      },
    ];

    final userProvider = Provider.of<UserProvider>(context);
    final uid = userProvider.user?.uid;
    final service = SavedPlacesService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(subcategoryName),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final p = places[index];
          final placeId = p['id'] as String;
          final img = p['image'] as String;

          return StreamBuilder<bool>(
            stream: uid != null
                ? service.isSavedStream(uid: uid, placeId: placeId)
                : Stream.value(false),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailsPage(
                        placeId: placeId,
                        name: p['name'] as String,
                        address: p['address'] as String,
                        rating: (p['rating'] as num).toDouble(),
                        imageUrl: img,
                        category: categoryName,
                        subcategory: subcategoryName,
                        lat: (p['lat'] as num).toDouble(),
                        lng: (p['lng'] as num).toDouble(),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 200,
                  child: Stack(
                    children: [
                      Hero(
                        tag: "place_$placeId",
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(img,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover),
                        ),
                      ),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),

                      // Heart button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () async {
                            if (userProvider.isGuest) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Login to save places"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            if (isSaved) {
                              await service.unsavePlace(uid: uid!, placeId: placeId);
                            } else {
                              await service.savePlace(
                                uid: uid!,
                                place: SavedPlace(
                                  id: placeId,
                                  name: p['name'] as String,
                                  category: categoryName,
                                  subcategory: subcategoryName,
                                  imageUrl: img,
                                  timestamp: Timestamp.now(),
                                ),
                              );
                            }
                          },
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            size: 30,
                            color: isSaved ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ),

                      // Text info
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 18, color: Colors.yellowAccent),
                                Text(
                                  (p['rating'] as num).toString(),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
