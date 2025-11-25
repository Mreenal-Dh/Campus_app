// lib/splash_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-navigation after 1.4 seconds
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/auth");
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Hybrid theme logic
    final bool isLight = brightness == Brightness.light;

    // Background gradient based on theme
    final gradient = isLight
        ? const LinearGradient(
            colors: [
              Color(0xFFE7ECF3),
              Color(0xFFDDE3EA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFF111418),
              Color(0xFF1A1D22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final textColor = isLight ? Colors.black : Colors.white;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // glass morph layer
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // App name with fade-in + scale animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: Text(
                "GoRaipur",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
