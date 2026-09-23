import 'package:flutter/material.dart';

class TitanColors {
  static const bg = Color(0xFF07090D);
  static const surface = Color(0xFF10151D);
  static const card = Color(0xFF171E2A);
  static const cardAlt = Color(0xFF1E2736);
  static const line = Color(0xFF2A3446);
  static const orange = Color(0xFFFF4D1C);
  static const orangeDim = Color(0xFFB33612);
  static const amber = Color(0xFFFFC857);
  static const mint = Color(0xFF3DDC97);
  static const cream = Color(0xFFF4F1EA);
  static const muted = Color(0xFF93A0B5);
  static const danger = Color(0xFFFF5D73);
  static const info = Color(0xFF4CC3FF);
}

class TitanTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: TitanColors.bg,
      primary: TitanColors.orange,
      secondary: TitanColors.amber,
      error: TitanColors.danger,
      onPrimary: Colors.white,
      onSurface: TitanColors.cream,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: TitanColors.bg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: TitanColors.cream,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TitanColors.cardAlt,
        contentTextStyle: const TextStyle(color: TitanColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TitanColors.card,
        hintStyle: const TextStyle(color: TitanColors.muted),
        labelStyle: const TextStyle(color: TitanColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TitanColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TitanColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TitanColors.orange, width: 1.4),
        ),
      ),
    );
  }
}
