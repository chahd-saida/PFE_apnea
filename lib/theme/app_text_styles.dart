import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Reusable TextStyles aligned with the doctor dashboard design tokens.
class AppTextStyles {
  AppTextStyles._();

  // --- Display / headers ---
  static const TextStyle displayLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // --- Titles ---
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // --- Body ---
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textBody,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textBody,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
  );

  // --- Labels ---
  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
  );

  // --- Metrics / data display ---
  static const TextStyle metricValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle ecgValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.success,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  // --- On-primary (white text for colored backgrounds) ---
  static const TextStyle onPrimaryTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle onPrimaryBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  static const TextStyle onPrimarySubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  // --- AppBar title ---
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // --- Button ---
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // --- Version / caption ---
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  // --- Breathing screen styles ---
  static TextStyle splashTime = GoogleFonts.dmSerifDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.tealMist,
  );

  static TextStyle splashMessage = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: AppColors.warmIvory,
  );
}
