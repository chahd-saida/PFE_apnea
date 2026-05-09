import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _navigationTimer = Timer(const Duration(seconds: 3), _navigateAfterSplash);
  }

  void _navigateAfterSplash() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.user != null;
    final isLoadingRole = auth.isLoadingRole;
    final role = auth.role;

    if (!isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }
    if (isLoadingRole) {
      _navigationTimer =
          Timer(const Duration(milliseconds: 400), _navigateAfterSplash);
      return;
    }
    if (role == 'doctor') {
      context.go(RouteNames.doctorDashboard);
      return;
    }
    if (role == 'patient') {
      context.go(RouteNames.patientDashboard);
      return;
    }
    context.go(RouteNames.fixProfile);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF5BBCB8);
    const gradientEnd  = Color(0xFF8ECFBF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: Stack(
          children: [
            // ── Subtle static halo ring (no pulse, matches mockup) ──────────
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
            ),

            // ── Scattered star dots ─────────────────────────────────────────
            _dot(top: 70,  left: 45,  size: 4),
            _dot(top: 130, right: 75, size: 3),
            _dot(top: 190, left: 65,  size: 5),
            _dot(top: 105, right: 38, size: 3),
            _dot(top: 210, right: 110, size: 4),

            // ── Main content ────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo card – ivory rounded square, ~95×95
                  Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: AppColors.warmIvory,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _MoonLogo(
                        animationController: _breathingController,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // "Respirez. Nous veillons."
                  Text(
                    'Respirez. Nous veillons.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.splashMessage.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Breathing wave
                  _BreathingWave(animationController: _breathingController),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'v1.0.0 • Apnea Detect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '© 2025 – All rights reserved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper – builds a small white dot star
  Widget _dot({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Moon logo – ivory card child
// ────────────────────────────────────────────────────────────────────────────
class _MoonLogo extends StatelessWidget {
  final AnimationController animationController;
  const _MoonLogo({required this.animationController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Gradient gives the teal depth visible in the mockup
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.tealMist.withValues(alpha: 0.85),
                  AppColors.tealAccent,
                ],
              ),
            ),
            child: CustomPaint(
              painter: _MoonCrescentPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Crescent painter – overlay color = warmIvory (matches card background)
// so the crescent illusion works on any background
// ────────────────────────────────────────────────────────────────────────────
class _MoonCrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Main teal circle (moon body)
    final paint = Paint()
      ..color = AppColors.tealAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Overlay circle carved out with warmIvory = crescent effect
    final overlayPaint = Paint()
      ..color = AppColors.warmIvory   // ← key fix: matches card bg, not nightBg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.30, center.dy - radius * 0.02),
      radius * 0.82,
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────────
// Breathing wave (unchanged)
// ────────────────────────────────────────────────────────────────────────────
class _BreathingWave extends StatelessWidget {
  final AnimationController animationController;
  const _BreathingWave({required this.animationController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(progress: animationController.value),
          size: const Size(200, 40),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const amplitude = 7.0;
    const wavelength = 40.0;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 1) {
      final phase = (x / wavelength + progress * 2 * pi) * 2 * pi;
      final y = size.height / 2 + amplitude * sin(phase);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}