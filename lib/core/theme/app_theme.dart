import 'package:flutter/material.dart';

class AppTheme {
  // --- 1. CORES ---
  static const Color primary = Color(0xFFFF5722);

  // O SEGREDO ESTAVA AQUI: Mudámos de 0xFF0F0F0F (Preto) para 0xFF121212 (Cinza Premium)
  static const Color background = Color(0xFF121212);

  static const Color surfaceDark = Color(
    0xFF1E1E1E,
  ); // Um pouco mais claro para destacar do fundo
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Colors.redAccent;

  // --- 2. ESPAÇAMENTOS GLOBAIS (Novo Padrão Compacto) ---
  static const double paddingScreen = 20.0;
  static const double paddingCard = 16.0;

  // --- 3. ARREDONDAMENTOS (Radii) ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // --- 4. TEMA GLOBAL DO FLUTTER ---
  static ThemeData get themeData {
    return ThemeData(
      // A LINHA MÁGICA: Desliga o motor novo do Flutter para devolver o cinza correto!
      useMaterial3: false,

      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor:
          surfaceDark, // Garante que os modais/gavetas não fiquem pretos
      // Bloqueia o Flutter de inventar cores
      colorScheme: const ColorScheme.dark(
        primary: primary,
        background: background,
        surface: surfaceDark,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),

      // Estilo global da AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),

      // Estilo global dos Botões (Finos e elegantes)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Estilo global dos Campos de Texto (Inputs compactos)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: textSecondary.withAlpha(128), fontSize: 13),
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
