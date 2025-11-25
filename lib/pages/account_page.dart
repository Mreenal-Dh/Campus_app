// lib/pages/account_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/theme_controller.dart';
import '../services/user_provider.dart';
import 'saved_places_page.dart';

/// Account page — sectioned, semi-glassy cards, centered profile header.
/// - Uses UserProvider for user data
/// - Uses ThemeController for theme switching
/// - Uses AuthService for sign-in/sign-out
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeController = Provider.of<ThemeController>(context, listen: false);
    final appUser = userProvider.user;

    // Gradient background (Option A)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: Theme.of(context).brightness == Brightness.light
          ? const [Color(0xFFF3F6FB), Color(0xFFE8ECF1)]
          : const [Color(0xFF0F1724), Color(0xFF111318)],
    );

    return Scaffold(
      // App bar transparent so gradient shows through
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Account"),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // subtle glass overlay behind cards (keeps background visible)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Page content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ===== PROFILE HEADER (CENTERED) =====
                    _ProfileHeader(appUser: appUser),

                    const SizedBox(height: 18),

                    // ===== APPEARANCE & THEME (glassy card) =====
                    _GlassSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(title: "Appearance"),
                          const SizedBox(height: 6),
                          _ThemeSelector(themeController: themeController),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== ACCOUNT ACTIONS (glassy card) =====
                    _GlassSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(title: "Account"),
                          const SizedBox(height: 6),

                          // Editable items — add handlers later
                          _MinimalRow(
                            text: appUser?.email ?? "No email (Guest)",
                            subText: appUser == null
                                ? null
                                : (appUser.isGuest ? "Guest account" : "IIITNR Student"),
                            onTap: () {},
                          ),
                          const Divider(height: 1),

                          _MinimalRow(text: "Saved Places", onTap: () {
                            if (userProvider.isGuest) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Login to access Saved Places")),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SavedPlacesPage()),
                            );
                          }),
                          const Divider(height: 1),

                          _MinimalRow(text: "TeamUp (requires login)", onTap: () {
                            if (userProvider.isGuest) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Login to access TeamUp")),
                              );
                              return;
                            }
                          }),
                          const Divider(height: 1),

                          _MinimalRow(text: "Edit Profile", onTap: () {}),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== PRIVACY & SUPPORT (glassy card) =====
                    _GlassSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(title: "Privacy & Support"),
                          const SizedBox(height: 6),

                          _MinimalRow(text: "Privacy Policy", onTap: () {}),
                          const Divider(height: 1),

                          _MinimalRow(text: "Report a bug", onTap: () {}),
                          const Divider(height: 1),

                          _MinimalRow(text: "Help & FAQ", onTap: () {}),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ===== LOG OUT / AUTH ACTIONS =====
                    _GlassSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (appUser == null || appUser.isGuest) ...[
                            // Guest: show login CTA and "end guest session"
                            ElevatedButton(
                              onPressed: () => _handleGoogleSignIn(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Login with Google (IIITNR)"),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () => _confirmLogout(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Log out"),
                            ),
                          ] else ...[
                            // Logged-in user: show logout and account info
                            OutlinedButton(
                              onPressed: () => _confirmLogout(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.16)),
                              ),
                              child: const Text("Log out"),
                            )
                          ],

                          const SizedBox(height: 12),
                          // small version info
                          Center(child: Text("GoRaipur • Version 1.0.0", style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.7)))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AuthService().signOut();
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(const SnackBar(content: Text("Signing in...")));
    final result = await AuthService().signInWithGoogle();
    scaffold.hideCurrentSnackBar();
    if (result != null) {
      scaffold.showSnackBar(SnackBar(content: Text(result)));
    } else {
      scaffold.showSnackBar(const SnackBar(content: Text("Signed in successfully")));
    }
  }
}

/// Centered profile header widget (Option A)
class _ProfileHeader extends StatelessWidget {
  final dynamic appUser;
  const _ProfileHeader({this.appUser});

  @override
  Widget build(BuildContext context) {
    final name = appUser?.name ?? (appUser?.isGuest == true ? "Guest User" : "Welcome");
    final email = appUser?.email;
    final photo = appUser?.photoUrl;

    return Column(
      children: [
        // Glass avatar holder
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).brightness == Brightness.light ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person, size: 46, color: Colors.white) : null,
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile coming soon')),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Centered name only (no inline icon to preserve centering)
        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        if (email != null) ...[
          const SizedBox(height: 6),
          Text(email, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.75))),
        ],
      ],
    );
  }
}

/// Semi-glassy card wrapper used for sections
class _GlassSection extends StatelessWidget {
  final Widget child;
  const _GlassSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardColor = isLight ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.06);
    final borderColor = isLight ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
    final shadowColor = Colors.black.withOpacity(isLight ? 0.06 : 0.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: child),
      ),
    );
  }
}

/// Minimal row style (Style C) — flexible and compact
class _MinimalRow extends StatelessWidget {
  final String text;
  final String? subText;
  final VoidCallback? onTap;

  const _MinimalRow({required this.text, this.subText, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyLarge!.color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          if (subText != null) ...[
            const SizedBox(height: 6),
            Text(subText!, style: TextStyle(color: color!.withOpacity(0.68))),
          ],
        ]),
      ),
    );
  }
}

/// Section title used inside cards
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyLarge!.color;
    return Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color));
  }
}

/// Theme selector widget (wired to ThemeController)
class _ThemeSelector extends StatelessWidget {
  final ThemeController themeController;
  const _ThemeSelector({required this.themeController});

  @override
  Widget build(BuildContext context) {
    final choice = themeController.choice;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ThemeChip(label: "System", selected: choice == AppThemeChoice.system, onTap: () => themeController.setChoice(AppThemeChoice.system), textColor: textColor!),
        _ThemeChip(label: "Light", selected: choice == AppThemeChoice.light, onTap: () => themeController.setChoice(AppThemeChoice.light), textColor: textColor),
        _ThemeChip(label: "Dark", selected: choice == AppThemeChoice.dark, onTap: () => themeController.setChoice(AppThemeChoice.dark), textColor: textColor),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color textColor;

  const _ThemeChip({required this.label, required this.selected, required this.onTap, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : textColor.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : textColor.withOpacity(0.75), fontWeight: FontWeight.w600)),
      ),
    );
  }
}
