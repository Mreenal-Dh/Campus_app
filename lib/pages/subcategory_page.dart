// lib/pages/subcategory_page.dart
import 'package:flutter/material.dart';
import '../models/place_models.dart';
import 'place_list_page.dart';


class SubcategoryPage extends StatelessWidget {
  final Category category;

  const SubcategoryPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final subcats = category.subcategories;

    // Some safe gradients to rotate through:
    final gradients = [
      [Colors.blue, Colors.cyan],
      [Colors.orange, Colors.red],
      [Colors.purple, Colors.pink],
      [Colors.green, Colors.teal],
      [Colors.indigo, Colors.deepPurple],
      [Colors.amber, Colors.deepOrangeAccent],
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(category.name, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color ?? Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: subcats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final sub = subcats[index];
            final colors = gradients[index % gradients.length];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceListPage(
                      categoryName: category.name,
                      subcategoryName: sub,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                    gradient:
                      LinearGradient(colors: colors.map((c) => c.withValues(alpha: 0.85)).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
