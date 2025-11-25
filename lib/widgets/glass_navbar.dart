// lib/widgets/glass_navbar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    
    // Determine if user is guest
    final isGuest = AuthService().isGuest;

    // Which pages are restricted for guest mode
    // 0 = TeamUp (only this is restricted now, Account is accessible for theme/logout)
    const restrictedTabs = {0};

    // Adaptive tint based on background - use inverted semi-transparent color
    final glassColor = scaffoldBg.withValues(
      alpha: brightness == Brightness.dark ? 0.15 : 0.12,
    );
    
    // Icon and text colors adapt to background
    final iconColor = brightness == Brightness.dark ? Colors.white : Colors.black87;

    final borderColor = iconColor.withValues(alpha: 0.08);

    final shadowColor = Colors.black.withValues(
      alpha: brightness == Brightness.dark ? 0.4 : 0.2,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 72,
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_icons.length, (index) {
                final isSelected = currentIndex == index;
                final isRestricted = isGuest && restrictedTabs.contains(index);

                final iconOpacity = isRestricted
                    ? 0.30   // Dimmed for guest
                    : (isSelected ? 1.0 : 0.7);

                return GestureDetector(
                  onTap: () {
                    if (isRestricted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Login to access this feature"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    onTap(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.20 : 1.0,
                          duration: const Duration(milliseconds: 260),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _icons[index],
                                color: iconColor.withValues(alpha: iconOpacity),
                                size: isSelected ? 28 : 24,
                              ),

                              // Glowing active-dot only if:
                              // selected AND not restricted
                              if (!isRestricted)
                                Positioned(
                                  bottom: -12,
                                  child: AnimatedOpacity(
                                    opacity: isSelected ? 1.0 : 0.0,
                                    duration:
                                        const Duration(milliseconds: 260),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: iconColor,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: iconColor.withValues(alpha: 0.45),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: TextStyle(
                            fontSize: isSelected ? 12 : 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: iconColor.withValues(alpha: iconOpacity),
                          ),
                          child: Text(_labels[index]),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

const _icons = [
  Icons.group,    // TeamUp
  Icons.explore,  // Explore
  Icons.home,     // Home
  Icons.place,    // Places
  Icons.person,   // Account
];

const _labels = [
  "TeamUp",
  "Explore",
  "Home",
  "Places",
  "Account",
];
