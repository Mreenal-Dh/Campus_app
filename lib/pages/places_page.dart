// lib/pages/places_page.dart
import 'package:flutter/material.dart';
import '../models/place_models.dart';
import 'subcategory_page.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  List<Category> _buildLocalCategories() {
    return [
      Category.local(
        id: 'essentials',
        name: 'Essentials',
        icon: Icons.local_hospital,
        gradientColors: [Colors.blue, Colors.cyan],
        subcategories: ['Medical', 'Pharmacies', 'ATMs'],
      ),
      Category.local(
        id: 'food',
        name: 'Food',
        icon: Icons.restaurant,
        gradientColors: [Colors.orange, Colors.red],
        subcategories: ['Restaurants', 'Cafes', 'Street Food'],
      ),
      Category.local(
        id: 'fun',
        name: 'Fun',
        icon: Icons.celebration,
        gradientColors: [Colors.purple, Colors.pink],
        subcategories: ['Malls', 'Parks', 'Hangout Spots'],
      ),
      Category.local(
        id: 'spiritual',
        name: 'Spiritual',
        icon: Icons.temple_hindu,
        gradientColors: [Colors.amber, Colors.deepOrange],
        subcategories: ['Temples'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildLocalCategories();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Places",
                style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final Category c = categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubcategoryPage(
                              category: c,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: c.gradientColors
                              .map((col) => col.withValues(alpha: 0.9))
                              .toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c.icon, color: Colors.white, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              c.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
