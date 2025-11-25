// lib/main_app.dart
import 'package:flutter/material.dart';

import 'widgets/glass_navbar.dart';

import 'pages/home_page.dart';
import 'pages/explore_page.dart';
import 'pages/teamup_page.dart';
import 'pages/places_page.dart';
import 'pages/account_page.dart';

class MainApp extends StatefulWidget {
  final bool isGuest;
  const MainApp({super.key, this.isGuest = false});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currentIndex = 2;
  final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  late final pages = [
    const TeamUpPage(),
    const ExplorePage(),
    HomePage(
      key: homeKey,
      onNavigateToExplore: () => setState(() => currentIndex = 1),
    ),
    const PlacesPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: GlassNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          if (index == 2) homeKey.currentState?.resetToExplore();
        },
      ),
    );
  }
}
