import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OasisColors {
  // Deep Calm Oasis Backgrounds
  static const Color background = Color(0xFF0D1714);
  static const Color surface = Color(0xFF152420);
  static const Color surfaceLight = Color(0xFF1E322C);
  static const Color card = Color(0xFF182A25);
  static const Color cardBorder = Color(0xFF26423A);

  // Oasis Greens
  static const Color primary = Color(0xFF10B981);
  static const Color primaryGlow = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF047857);
  static const Color accentMint = Color(0xFF6EE7B7);

  // Break & Warning Accents
  static const Color breakBlue = Color(0xFF38BDF8);
  static const Color breakPurple = Color(0xFFA855F7);
  static const Color coinGold = Color(0xFFFBBF24);
  static const Color coinGoldDark = Color(0xFFD97706);
  static const Color witheredRed = Color(0xFFF87171);
  static const Color witheredBrown = Color(0xFF78350F);

  // Text
  static const Color textPrimary = Color(0xFFF0FDF4);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class OasisTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OasisColors.background,
      colorScheme: const ColorScheme.dark(
        primary: OasisColors.primary,
        secondary: OasisColors.accentMint,
        surface: OasisColors.surface,
        error: OasisColors.witheredRed,
        onPrimary: Colors.white,
        onSurface: OasisColors.textPrimary,
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: OasisColors.textPrimary,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: OasisColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: OasisColors.textPrimary,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: OasisColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: OasisColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: OasisColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: OasisColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: OasisColors.cardBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: OasisColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: OasisColors.cardBorder, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OasisColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: OasisColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
