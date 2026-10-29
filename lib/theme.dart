import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette « gaie et fraîche », reprise du logo.
class AppColors {
  static const navy = Color(0xFF1D3461);
  static const navyLight = Color(0xFF2E5A9C);
  static const coral = Color(0xFFF26B5B);
  static const sun = Color(0xFFFFC94D);
  static const mint = Color(0xFF7ED6B2);
  static const sky = Color(0xFF8EC9F2);
  static const cream = Color(0xFFFFF8EC);
  static const ink = Color(0xFF2A2A3A);
  static const lilac = Color(0xFFB9A6E8);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      primary: AppColors.coral,
      secondary: AppColors.navy,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );
  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.navy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

/// Police du texte des histoires : Andika, conçue pour les jeunes lecteurs
/// (lettres bien distinctes, « a » et « g » simples).
TextStyle storyTextStyle(double size) {
  TextStyle style;
  try {
    style = GoogleFonts.getFont('Andika');
  } catch (_) {
    style = GoogleFonts.nunito();
  }
  return style.copyWith(fontSize: size, height: 1.55, color: AppColors.ink);
}
