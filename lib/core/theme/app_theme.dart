import 'package:flutter/material.dart';

class AppTheme {
  // --- 1. CORES ---
  static const Color primary = Color(
    0xFF30D158,
  );

  static const Color splash = primary;
  static const Color background = Color(0xFF131314);
  static const Color iosBlue = Color(0xFF00B4D8);
  static const Color silverGrey = Color.fromRGBO(255, 255, 255, 0.5);
  static const Color surfaceDark = Color(0xFF1E1F20);
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color buttonSurface = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0x99EBEBF5);
  static const Color textTertiary = Color(0x4DEBEBF5);
  static const Color textLabel = Color(0xFF8E8E93);
  static const Color accentMetrics = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF4CAF50);

  // --- 2. ESPAÇAMENTOS GLOBAIS
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

  // --- 2.1 CONVENIENCE PADDINGS ---
  static const EdgeInsets edgeInsetsSmall = EdgeInsets.all(8);

  // --- 3. ARREDONDAMENTOS (Radii) ---
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 9999.0;

  // --- 4. ESTILOS DE TEXTO ---
  static const TextStyle bigTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppTheme.textPrimary,
  );

  static TextStyle textSectionHeaderDark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    letterSpacing: -0.3,
  );

  static const  TextStyle pageTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    color: textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle cardTitle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: textPrimary,
      letterSpacing: -0.2
  );

  static const TextStyle cardSubtitle = TextStyle(
      fontSize: 12,
      color: textSecondary,
      fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
  );

  static const TextStyle microLabelTextStyle = TextStyle(
    color: AppTheme.silverGrey,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  // --- 5. DECORAÇÕES (Bordas e Sombras) ---
  static final Border cardBorder = Border.all(color: Colors.white.withAlpha(15), width: 1);

  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withAlpha(50),
    blurRadius: 3,
    offset: const Offset(0, 2),
  );

  /// Decoração padrão para cards, reutilizável em containers e widgets de cartão.
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppTheme.surfaceDark,
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    boxShadow: [AppTheme.cardShadow],
    border: AppTheme.cardBorder,
  );

  // --- 6. COMPONENTES (Tokens) ---
  static TooltipThemeData get tooltipTheme => TooltipThemeData(
    decoration: BoxDecoration(
      color: surfaceDark,
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(color: primary.withAlpha(100)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(100),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(horizontal: 24),
    preferBelow: false,
    triggerMode: TooltipTriggerMode.tap,
    waitDuration: Duration.zero,
    showDuration: const Duration(seconds: 3),
  );

  // --- 7. TEMA GLOBAL DO FLUTTER ---
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: surfaceDark,
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
          foregroundColor: Colors.black,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
            minimumSize: const Size(double.infinity, 48)
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 10,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          extendedTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium)
        )
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: TextStyle(
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
      tooltipTheme: tooltipTheme,
    );
  }
}