  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';

  class AppTheme {
    // --- 1. CORES ---
    static const Color primary = Color(
      0xFF30D158,
    ); // Verde para interações principais
    // Splash color token (uses the same green by default). Use this token
    // everywhere for ripple/splash colors so changing it here updates all spots.
    static const Color splash = primary;
    static const Color background = Color(0xFF121212);

    static const Color iosBlue = Color(0xFF00B4D8);
    static const Color silverGrey = Color.fromRGBO(255, 255, 255, 0.5);

    static const Color surfaceDark = Color(0xFF1D1D1D);
    static const Color surfaceLight = Color(0xFF2C2C2E);
    static const Color buttonSurface = Color(0xFF1E1E1E);
    static const Color textPrimary = Color(0xFFF7FBFF);
    static const Color textSecondary = Color(0xFF94A3B8);
    static const Color accentMetrics = Color(0xFFFF9F0A);
    static const Color success = Color(0xFF4CAF50);

    // --- 2. ESTILOS DE TEXTO ---
    static const TextStyle microLabelTextStyle = TextStyle(
      color: AppTheme.silverGrey,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    static const TextStyle bigTitle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: AppTheme.textPrimary,
    );



    static final Border cardBorder = Border.all(color: Colors.white.withAlpha(15), width: 0.5);
    static final BoxShadow cardShadow = BoxShadow(
      color: Colors.black.withAlpha(50),
      blurRadius: 1,
      offset: const Offset(1, 1),
    );


    static const  TextStyle pageTitle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: AppTheme.textPrimary,
    );

    static TextStyle textSectionHeaderDark = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
      letterSpacing: -0.5,
    );

    // --- 3. ESPAÇAMENTOS GLOBAIS (Novo Padrão Compacto) ---
    static const double paddingScreen = 16;
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

    // --- 4. ARREDONDAMENTOS (Radii) ---
    static const double radiusSmall = 8.0;
    static const double radiusMedium = 12.0;
    static const double radiusLarge = 18.0;
    static const double radiusFull = 9999.0;

    // --- 5. TEMA GLOBAL DO FLUTTER ---
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
          surface: surfaceDark,
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