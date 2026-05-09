import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

// Central theme configuration. Aligned with the doctor dashboard design tokens.
// Usage: MaterialApp(theme: AppTheme.theme, darkTheme: AppTheme.darkTheme)
class AppTheme {
  AppTheme._();

  // -------------------------------------------------------------------------
  // Light theme
  // -------------------------------------------------------------------------
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDark,
        onError: Colors.white,
      ),

      // AppBar — solid primary color matching header gradient start
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppDimensions.xs / 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        shadowColor: Colors.black12,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 4,
        ),
      ),

      // Bottom navigation bar — matches dashboard pill style
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Text theme mapped to AppTextStyles
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        thickness: 1,
        space: AppDimensions.md,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
      ),

      // Icon
      iconTheme: const IconThemeData(color: AppColors.textMedium),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        labelStyle: AppTextStyles.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Dark theme
  // -------------------------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppDimensions.xs / 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.textMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.textMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 4,
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.darkTextSecondary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
        bodySmall: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.textMedium,
        thickness: 1,
        space: AppDimensions.md,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Static helper decorations (reused across screens)
  // -------------------------------------------------------------------------

  /// Header gradient: primary navy → blue accent (matches doctor dashboard header)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// AI / analytics section gradient: dark purple → purple
  static const LinearGradient aiSectionGradient = LinearGradient(
    colors: [AppColors.aiDark, AppColors.aiPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Standard card shadow matching doctor dashboard stat cards
  static List<BoxShadow> cardShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  /// Default card shadow (color-neutral)
  static const List<BoxShadow> defaultCardShadow = [
    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
  ];

  /// Status badge decoration — tinted background + border
  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
    border: Border.all(color: color.withValues(alpha: 0.3)),
  );
  // -------------------------------------------------------------------------
  // Static shortcuts for colors (using AppColors)
  // -------------------------------------------------------------------------
  static Color get primary => AppColors.primary;
  static Color get primaryLight => AppColors.primaryLight;
  static Color get secondary => AppColors.primaryLight; // alias
  static Color get success => AppColors.success;
  static Color get danger => AppColors.error; // alias error
  static Color get warning => AppColors.warning;
  static Color get background => AppColors.background;
  static Color get surface => AppColors.surface;
  static Color get textDark => AppColors.textDark;
  static Color get textBody => AppColors.textBody;
  static Color get textMedium => AppColors.textMedium;
  static Color get textLight => AppColors.textLight;
  static Color get darkBackground => AppColors.darkBackground;
  static Color get darkSurface => AppColors.darkSurface;
  static Color get darkTextPrimary => AppColors.darkTextPrimary;
  static Color get darkTextSecondary => AppColors.darkTextSecondary;

  // -------------------------------------------------------------------------
  // Static shortcuts for dimensions (using AppDimensions)
  // -------------------------------------------------------------------------
  static double get xs => AppDimensions.xs;
  static double get sm => AppDimensions.sm;
  static double get md => AppDimensions.md;
  static double get lg => AppDimensions.lg;
  static double get xl => AppDimensions.xl;
  static double get radiusXs => AppDimensions.radiusXs;
  static double get radiusSm => AppDimensions.radiusSm;
  static double get radiusMd => AppDimensions.radiusMd;
  static double get radiusLg => AppDimensions.radiusLg;
  static double get radiusXl => AppDimensions.radiusXl;
  static double get buttonHeight => AppDimensions.buttonHeight;
  static double get buttonHeightSm => AppDimensions.buttonHeightSm;
  static double get screenPadding => AppDimensions.screenPadding;
  static double get cardPadding => AppDimensions.cardPadding;

  // -------------------------------------------------------------------------
  // Static shortcuts for text styles (using AppTextStyles)
  // -------------------------------------------------------------------------
  static TextStyle get screenTitle => AppTextStyles.headlineMedium;
  static TextStyle get sectionHeader => AppTextStyles.titleLarge;
  static TextStyle get metricValue => AppTextStyles.metricValue;
  static TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  static TextStyle get bodyMedium => AppTextStyles.bodyMedium;

  // -------------------------------------------------------------------------
  // Common card decoration (matching doctor dashboard style)
  // -------------------------------------------------------------------------
  static BoxDecoration getCardDecoration({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      boxShadow: defaultCardShadow,
    );
  }
}
