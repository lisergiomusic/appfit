import 'package:flutter/material.dart';

class AppTheme {
  // 1. Nossa Paleta de Cores Oficial
  static const Color background = Color(0xFF121212); // Cinza Chumbo
  static const Color primary = Color(0xFFFF5722); // Laranja Queimado
  static const Color surfaceDark = Color(
    0xFF1E1E1E,
  ); // Fundo de cartões mais escuro
  static const Color surfaceLight = Color(
    0xFF2A2A2A,
  ); // Fundo de campos de texto
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color success = Color(0xFF00E676); // Verde para metas batidas

  // 2. Configuração Global do Tema
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      useMaterial3: true,

      // Configuração padrão da AppBar para o app todo
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        centerTitle: true,
      ),

      // Configuração padrão dos botões laranjas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),

      // Configuração padrão dos TextFields (Campos de texto)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
