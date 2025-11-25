// lib/landing_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // FIXED IMPORT

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AuthService _auth = AuthService();  // CREATE INSTANCE
  bool _loading = false;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);

    final result = await _auth.signInWithGoogle();

    setState(() => _loading = false);

    if (result != null) {
      // result contains error message
      _showError(result);
    }
    // if result is null, sign-in succeeded and authStateChanges will navigate automatically
  }

  Future<void> _guestLogin() async {
    setState(() => _loading = true);

    await _auth.signInAsGuest(); // returns void → no result to check

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    final bgGradient = isLight
        ? const LinearGradient(
            colors: [Color(0xFFF3F6FB), Color(0xFFE8ECF1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF14171C), Color(0xFF1A1D23)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final textColor = isLight ? Colors.black : Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(color: Colors.transparent),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "GoRaipur",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Smart travel for Raipur students",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 60),

                _LandingButton(
                  text: "Continue with Google",
                  icon: Icons.login,
                  onPressed: _loading ? null : _googleLogin,
                ),

                const SizedBox(height: 18),

                _LandingButton(
                  text: "Continue as Guest",
                  icon: Icons.person_outline,
                  onPressed: _loading ? null : _guestLogin,
                ),

                const SizedBox(height: 40),

                if (_loading)
                  const CircularProgressIndicator(strokeWidth: 2.4),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _LandingButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const _LandingButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: (isLight ? Colors.black : Colors.white).withOpacity(0.6),
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isLight ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isLight ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
