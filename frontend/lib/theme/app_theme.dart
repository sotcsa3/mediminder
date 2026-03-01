// MediMinder – App Theme (Material 3)
// Matching the existing CSS color palette, optimized for elderly users

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main colors (from CSS custom properties)
  static const Color primaryColor = Color(0xFF2E7D6F);
  static const Color primaryLight = Color(0xFF3A9D8C);
  static const Color primaryDark = Color(0xFF1E5C50);
  static const Color primaryBg = Color(0xFFE8F5F1);

  static const Color secondaryColor = Color(0xFFFF8F00);
  static const Color secondaryLight = Color(0xFFFFB74D);

  static const Color bgColor = Color(0xFFF5F5F0);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textLight = Color(0xFF9E9E9E);

  static const Color successColor = Color(0xFF4CAF50);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color dangerBg = Color(0xFFFFEBEE);
  static const Color warningColor = Color(0xFFFF8F00);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color borderColor = Color(0xFFE0E0E0);

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: dangerColor,
      ),
      scaffoldBackgroundColor: bgColor,
      textTheme: baseTextTheme.copyWith(
        // Larger fonts for elderly users
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: primaryDark,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 18,
          color: textColor,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 14,
          color: textLight,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(
          fontSize: 16,
          color: textSecondary,
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 16,
          color: textLight,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
