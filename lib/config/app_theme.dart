import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1565C0); // Biru Gelap
  static const Color seedColor = Color(0xFF1E88E5); // Biru Standar
  static const Color secondaryColor = Color(0xFFFF6F00); // Oranye (Aksen)
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Colors.redAccent;

  // Definisi Tema Global
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Skema Warna
      colorScheme: _buildColorScheme(),

      // Font Global: Poppins
      textTheme: GoogleFonts.poppinsTextTheme(),

      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      pageTransitionsTheme: _buildPageTransitionsTheme(),
    );
  }

  // Metode untuk membangun ColorScheme
  static ColorScheme _buildColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      // Di Flutter terbaru, properti 'background' dipindahkan ke 'surface'
      // Namun jika ingin mendefinisikan background canvas secara spesifik:
      error: errorColor,
    ).copyWith(
      surface: backgroundColor, // Menggantikan parameter background yang deprecated
    );
  }

  // Metode untuk membangun AppBarTheme
  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
    );
  }

  // Metode untuk membangun ElevatedButtonTheme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 2,
      ),
    );
  }

  // Metode untuk membangun InputDecorationTheme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: Colors.grey),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
    );
  }

  // Metode untuk membangun PageTransitionsTheme (SUDAH DIPERBAIKI)
  static PageTransitionsTheme _buildPageTransitionsTheme() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(), 
        // Mengganti CupertinoPageTransitionsBuilder dengan ZoomPageTransitionsBuilder
        // agar lolos build di Flutter 3.44.x ke atas
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    );
  }
}
