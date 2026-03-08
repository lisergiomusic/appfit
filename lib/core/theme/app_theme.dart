import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- 1. CORES ---
  static const Color primary = Color(0xFF30D158); // Atualizado para verde
  static const Color background = Color(0xFF000000); // Tailwind background-dark
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosAmber = Color(0xFFFFBF00);
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color silverGrey = Color.fromRGBO(255, 255, 255, 0.5);

  static const Color surfaceDark = Color(0xFF0e0e0f);
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color.fromARGB(160, 255, 255, 255);
  static const Color accentMetrics = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Colors.redAccent;

  // Glassmorphism helpers
  static Color get glassCard =>
      const Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static Color get glassPill =>
      const Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  // --- 2. ESPAÇAMENTOS GLOBAIS (Novo Padrão Compacto) ---
  static const double paddingScreen = 20.0;
  static const double paddingCard = 16.0;
  static const double space0 = 0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space36 = 36.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // --- 3. ARREDONDAMENTOS (Radii) ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 9999.0;

  // --- 4. TEMA GLOBAL DO FLUTTER ---
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: surfaceDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        background: background,
        surface: surfaceDark,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(
          color: textSecondary.withAlpha(128),
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primary, width: 1.0),
        ),
      ),
    );
  }
}
