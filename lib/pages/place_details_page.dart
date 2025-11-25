// lib/pages/place_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/saved_places_service.dart';
import '../services/user_provider.dart';
import '../models/saved_place.dart';

class PlaceDetailsPage extends StatelessWidget {
  final String placeId;
  final String name;
  final String address;
  final double rating;
  final String imageUrl;
  final String category;
  final String subcategory;
  final double? lat;
  final double? lng;

  const PlaceDetailsPage({
    super.key,
    required this.placeId,
    required this.name,
    required this.address,
    required this.rating,
    required this.imageUrl,
    required this.category,
    required this.subcategory,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final uid = userProvider.user?.uid;

    final service = SavedPlacesService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Heart button
          StreamBuilder<bool>(
            stream: uid != null
                ? service.isSavedStream(uid: uid, placeId: placeId)
                : Stream.value(false),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? Colors.redAccent : Colors.white,
                  size: 30,
                ),
                onPressed: () async {
                  if (userProvider.isGuest) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Login to save places"),
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
                        name: name,
                        category: category,
                        subcategory: subcategory,
                        imageUrl: imageUrl,
                        timestamp: Timestamp.now(),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Hero(
            tag: "place_$placeId",
            child: Image.asset(
              imageUrl,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.star,
                        color: Colors.yellowAccent, size: 22),
                    const SizedBox(width: 6),
                    Text(rating.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on,
                        color: Colors.redAccent, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(address,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Description",
                  style: TextStyle(
                      color: Colors.white70, fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 20),

                if (lat != null && lng != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x300&markers=color:red|$lat,$lng&key=YOUR_API_KEY",
                    ),
                  ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    final query = Uri.encodeComponent("$name, $address");
                    final url =
                        "https://www.google.com/maps/search/?api=1&query=$query";
                    launchUrl(Uri.parse(url));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Open in Google Maps",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
