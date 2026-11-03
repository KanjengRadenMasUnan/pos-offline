import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme: "Tactile Monolith POS" Design System
/// Anti-slop philosophy:
/// - Zero generic AI aesthetics: no purple/blue gradients, no glassmorphism, no puffy round cards everywhere.
/// - Characterful typography: Plus Jakarta Sans for structural UI, JetBrains Mono for all numeric/tabular figures.
/// - Restrained palette: Warm archival bone chalk canvas (#F7F7F4), deep carbon ink (#131416), hairline borders (#E2E2DC).
/// - Purposeful utility: Tight mechanical grouping, recessed touch wells, surgical signal accents.
class AppTheme {
  // --- COLOR PALETTE TOKENS ---
  static const Color backgroundColor = Color(0xFFF7F7F4); // Archival Bone Chalk
  static const Color surfaceColor = Color(0xFFFFFFFF);     // Stark Card White
  static const Color surfaceRecessed = Color(0xFFEFEFEA); // Recessed tactile keybed/well
  static const Color cardBorderColor = Color(0xFFE2E2DC); // 1px architectural hairline

  static const Color primaryColor = Color(0xFF131416);    // Carbon Black
  static const Color primaryDark = Color(0xFF0A0A0C);     // Deep Obsidian
  static const Color secondaryColor = Color(0xFF28292E);  // Lead Iron
  static const Color seedColor = Color(0xFF131416);

  static const Color textPrimary = Color(0xFF131416);    // Carbon Ink
  static const Color textSecondary = Color(0xFF4C4E55);  // Asphalt Ink
  static const Color textMuted = Color(0xFF8B8E96);      // Graphite Hairline

  // Surgical Signal Accents (Non-neon, pigment based)
  static const Color successColor = Color(0xFF1B7A53);    // Archival Forest Green
  static const Color warningColor = Color(0xFFBA7506);    // Raw Brass Amber
  static const Color errorColor = Color(0xFFD63929);      // Stamp Cinnabar Red

  static const Color forestGreen = successColor;
  static const Color rawBrass = warningColor;
  static const Color stampRed = errorColor;
  static const Color leadAsphalt = Color(0xFF4C4E55);
  static const Color slateGraphite = Color(0xFF8B8E96);

  // --- TYPOGRAPHIC TOKENS ---
  static TextStyle get fontPrimary => GoogleFonts.plusJakartaSans();
  static TextStyle get fontMono => GoogleFonts.jetBrainsMono();

  static TextStyle monoNumeric({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle labelCaps({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w800,
    Color color = textSecondary,
    double letterSpacing = 0.8,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle editorialTitle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w800,
    Color color = textPrimary,
    double letterSpacing = -0.4,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // --- GLOBAL THEME DATA ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _buildColorScheme(),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      dividerTheme: const DividerThemeData(
        color: cardBorderColor,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorderColor, width: 1),
        ),
      ),
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  static ColorScheme _buildColorScheme() {
    return const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimary,
      error: errorColor,
      onError: Colors.white,
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textPrimary, size: 20),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: cardBorderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaceRecessed,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cardBorderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cardBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 13),
      hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: cardBorderColor, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
    );
  }

  static PageTransitionsTheme _buildPageTransitionsTheme() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    );
  }
}
