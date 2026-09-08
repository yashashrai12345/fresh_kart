import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFFECFDF5); // Emerald 50
  static const Color primaryBorder = Color(0xFFA7F3D0); // Emerald 200

  static const Color accent = Color(0xFF10B981); // Emerald 500
  static const Color accentWarm = Color(0xFFF59E0B); // Amber 500
  static const Color accentWarmLight = Color(0xFFFEF3C7); // Amber 100

  static const Color bgMain = Color(0xFFF8FAFC); // Slate 50
  static const Color bgCard = Color(0xFFFFFFFF);

  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final outfitFont = GoogleFonts.outfit();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgMain,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: bgCard,
        error: danger,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: outfitFont.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textMain,
        ),
        displayMedium: outfitFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        headlineMedium: outfitFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        titleLarge: outfitFont.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 15,
          color: textMain,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        iconTheme: const IconThemeData(color: textMain),
        titleTextStyle: outfitFont.copyWith(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: outfitFont.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: textLight),
      ),
    );
  }
}
