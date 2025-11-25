// lib/pages/saved_places_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/saved_places_service.dart';
import '../services/user_provider.dart';
import '../models/saved_place.dart';
import 'place_details_page.dart';

class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Saved Places")),
        body: const Center(
          child: Text("No user found."),
        ),
      );
    }

    final service = SavedPlacesService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Saved Places"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<SavedPlace>>(
        stream: service.savedPlacesStream(uid: user.uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final places = snap.data!;

          if (places.isEmpty) {
            return const Center(
              child: Text(
                "No saved places yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _SavedPlaceCard(place: places[index]);
            },
          );
        },
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final SavedPlace place;
  const _SavedPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        // Navigate to details page — use full data (NOT placeId)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailsPage(
              placeId: place.id,
              name: place.name,
              address: "",                // we don't store address in SavedPlace yet
              rating: 0,                  // will integrate real data later
              imageUrl: place.imageUrl,
              category: place.category,
              subcategory: place.subcategory,
              lat: null,
              lng: null,
            ),
          ),
        );
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            // IMAGE (assets, not network)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.asset(
                place.imageUrl,
                width: 140,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 140,
                  height: 110,
                  color: Colors.grey[800],
                  child: const Icon(Icons.photo, color: Colors.white54),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${place.category} • ${place.subcategory}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(place.timestamp),
                          style: const TextStyle(color: Colors.white54),
                        ),
                        IconButton(
                          onPressed: () async {
                            await SavedPlacesService().unsavePlace(
                              uid: userProvider.user!.uid,
                              placeId: place.id,
                            );
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white70),
                          tooltip: "Remove",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp t) {
    final d = t.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }
}
