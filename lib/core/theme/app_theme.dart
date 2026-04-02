import 'package:flutter/material.dart';
import 'tokens/app_colors.dart';
export 'tokens/spacing_tokens.dart';
export 'tokens/app_colors.dart';

class AppTheme {
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
  static const double radiusXS = 4;
  static const double radiusSM = 8;
  static const double radiusMD = 10;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 9999.0;
  static const Radius pill = Radius.circular(9999);

  // --- 4. ESTILOS DE TEXTO ---
  static const TextStyle bigTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.37,
    height: 1,
    color: AppColors.labelPrimary,
  );

  static const title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.36,
    height: 1,
    color: AppColors.labelPrimary,
  );

  static TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    color: AppColors.labelSecondary,
    height: 1,
  );

  static const sectionAction = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    color: AppColors.primary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.labelPrimary,
  );

  static const TextStyle navBarAction = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: AppColors.primary,
  );

  static const TextStyle inputPlaceHolder = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: AppColors.labelTertiary,
  );

  static const inputText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: AppColors.labelPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    color: AppColors.labelPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.labelPrimary,
    letterSpacing: -0.41,
    height: 1,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 15,
    height: 1,
    color: AppColors.labelSecondary,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.labelSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
  );

  static const caption2 = TextStyle(
    fontSize: 11,
    color: AppColors.labelSecondary,
    letterSpacing: 0.07,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle formLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.24,
    color: AppColors.labelSecondary,
  );

  static const TextStyle microLabelTextStyle = TextStyle(
    color: AppColors.silverGrey,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  // --- 5. DECORAÇÕES (Bordas e Sombras) ---
  static final Border cardBorder = Border.all(
    color: Colors.white.withAlpha(5),
    width: 1,
  );

  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withAlpha(50),
    blurRadius: 3,
    offset: const Offset(0, 2),
  );

  /// Decoração padrão para cards, reutilizável em containers e widgets de cartão.
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
  );

  // --- 6. COMPONENTES (Tokens) ---
  static TooltipThemeData get tooltipTheme => TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: AppColors.primary.withAlpha(100)),
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
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.labelPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppBarTokens.pageTitle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXL),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 10,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        extendedTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.labelSecondary,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: AppColors.labelSecondary.withAlpha(128),
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
        ),
      ),
      tooltipTheme: tooltipTheme,
    );
  }
}

class CardTokens {
  static const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static BorderRadius cardRadius = BorderRadius.circular(AppTheme.radiusLG);
  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    height: 1,
    fontWeight: FontWeight.w600,
    color: AppColors.labelPrimary,
    letterSpacing: -0.41,
  );
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 15,
    height: 1,
    color: AppColors.labelSecondary,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
  );
}

class AppBarTokens {
  static const actionButton = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: AppColors.primary,
  );
  static const TextStyle pageTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.labelPrimary,
  );
}

class ButtonTokens {
  ButtonTokens._();

  static const double primaryHeight = 50.0;
  static const double primaryRadius = 14.0;
  static const double secondaryHeight = 50.0;
  static const double secondaryRadius = 14.0;

  static const TextStyle primaryTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.primary,
  );

  static const TextStyle secondaryTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.labelPrimary,
  );

  static const TextStyle destructiveTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: AppColors.systemRed,
  );

  static BoxDecoration primaryDecoration = BoxDecoration(
    color: AppColors.primary.withAlpha(25),
    borderRadius: BorderRadius.circular(primaryRadius),
  );

  static BoxDecoration secondaryDecoration = BoxDecoration(
    color: AppColors.fillSecondary,
    borderRadius: BorderRadius.circular(secondaryRadius),
  );
}

class AvatarTokens {
  static const double sm = 14.0; // diâmetro 28 — tab bar, listas densas
  static const double md = 20.0; // diâmetro 40 — listas padrão
  static const double lg = 28.0; // diâmetro 56 — cabeçalhos de perfil, home
}

class PillTokens {
  static const TextStyle text = AppTheme.caption2;
  static BorderRadius radius = BorderRadius.circular(999);
  static Decoration decoration = BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: BorderRadius.circular(999),
  );
}

class ThumbnailTokens {
  static const double sm = 40.0;
  static const double md = 48.0;
  static const double lg = 60.0;
}
