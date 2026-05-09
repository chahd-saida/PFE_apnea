import 'package:flutter/material.dart';

// All app color constants, extracted from dashboard_doctor_screen.dart design tokens.
// Palette: Tailwind CSS slate/blue scale.
class AppColors {
  AppColors._();

  // --- Brand primary ---
  static const Color primary = Color(0xFF1E3A8A);      // Deep navy blue
  static const Color primaryLight = Color(0xFF3B82F6); // Blue accent (gradient end)

  // --- AI / analytics section ---
  static const Color aiPrimary = Color(0xFF6D28D9);    // Purple
  static const Color aiDark = Color(0xFF2E1065);       // Dark purple

  // --- Semantic ---
  static const Color success = Color(0xFF10B981);      // Green (ECG, OK)
  static const Color warning = Color(0xFFF59E0B);      // Amber
  static const Color error = Color(0xFFEF4444);        // Red (critical)
  static const Color info = Color(0xFF8B5CF6);         // Purple info
  static const Color rosePink = Color(0xFFF43F5E);     // Progress bar accent

  // --- Text ---
  static const Color textDark = Color(0xFF1E293B);     // Titles, section headers
  static const Color textBody = Color(0xFF475569);     // Body text, alert text
  static const Color textMedium = Color(0xFF64748B);   // Secondary text, icons
  static const Color textLight = Color(0xFF94A3B8);    // Timestamps, muted

  // --- Backgrounds & surfaces ---
  static const Color background = Color(0xFFF8FAFC);   // Scaffold background
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFE2E8F0); // Avatar bg, dividers

  // --- Dark mode ---
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // --- Score / health status (patient dashboard) ---
  static const Color scoreGood = Color(0xFF388E3C);
  static const Color scoreAverage = Color(0xFFF57C00);
  static const Color scorePoor = Color(0xFFC62828);
  static const Color scoreGoodBg = Color(0xFFE8F5E9);
  static const Color scoreAverageBg = Color(0xFFFFF3E0);
  static const Color scorePoorBg = Color(0xFFFFEBEE);

  // --- Monitoring / vital colors (patient stats) ---
  static const Color spo2 = Color(0xFF1565C0);
  static const Color spo2Bg = Color(0xFFE3F2FD);
  static const Color heartRate = Color(0xFFC62828);
  static const Color heartRateBg = Color(0xFFFFEBEE);
  static const Color temperature = Color(0xFF00695C);
  static const Color temperatureBg = Color(0xFFE0F2F1);
  static const Color eventOrange = Color(0xFFE65100);
  static const Color eventOrangeBg = Color(0xFFFFF3E0);

  // --- Breathing screen / night mode palette (NEW) ---
  static const Color nightBg = Color(0xFF0E2326);        // Teal night deep
  static const Color warmIvory = Color(0xFFF4F0E8);      // Warm ivory (light mode)
  static const Color tealAccent = Color(0xFF1F6F73);     // Teal deep accent
  static const Color tealMist = Color(0xFF9BC4C0);       // Teal mist (halos)
  static const Color textNightPrimary = Color(0xFF0F2A2E); // Night text ink
}
