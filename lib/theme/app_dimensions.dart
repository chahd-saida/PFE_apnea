// All spacing, border radius, and size constants for the app.
class AppDimensions {
  AppDimensions._();

  // --- Spacing scale ---
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // --- Border radius ---
  static const double radiusXs = 8.0;       // error containers, small chips
  static const double radiusSm = 10.0;      // inputs
  static const double radiusMd = 12.0;      // buttons, auth role cards
  static const double radiusLg = 16.0;      // alert cards, patient stat cards
  static const double radiusXl = 20.0;      // stat cards, ECG section, AI section
  static const double radiusNav = 30.0;     // bottom nav pill container
  static const double radiusHeader = 32.0;  // bottom corners of gradient header

  // --- Button dimensions ---
  static const double buttonHeight = 50.0;
  static const double buttonHeightSm = 40.0;

  // --- Icon sizes ---
  static const double iconXs = 16.0;
  static const double iconSm = 22.0;
  static const double iconMd = 26.0;
  static const double iconLg = 28.0;
  static const double iconXl = 80.0;   // splash screen / access denied illustrations

  // --- Standard padding presets ---
  static const double screenPadding = 16.0;  // horizontal body padding
  static const double cardPadding = 16.0;
  static const double cardPaddingLg = 20.0;

  // --- Grid spacing ---
  static const double gridSpacing = 16.0;
  static const double gridSpacingSm = 12.0;
}
