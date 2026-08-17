// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/**
 * Premium design system theme tokens for Back2Kasi.
 *
 * <p>Uses Material 3 design spec with a rich, dark-mode-first aesthetic.
 * Colors are tailored around a deep midnight slate base, with premium indigo and
 * vibrant warm gold accents representing Kasi nighttime lights.</p>
 *
 * <p>Typography is driven by Google Fonts (Outfit) for a modern, clean,
 * and high-end tech-product appearance.</p>
 */
class AppTheme {
  // Midnight Theme Colors
  static const Color primaryColor = Color(0xFF5D5FEF); // Premium Indigo
  static const Color accentColor = Color(0xFFFFB74D);  // Warm Kasi Gold
  static const Color backgroundColor = Color(0xFF0F0E17); // Deep Slate Black
  static const Color surfaceColor = Color(0xFF161524);    // Card/Sheet Dark Slate
  static const Color textPrimaryColor = Color(0xFFFFFEFA);  // Warm Off-White
  static const Color textSecondaryColor = Color(0xFF94A3B8); // Slate Gray
  static const Color errorColor = Color(0xFFEF5350);      // Soft Coral Red
  static const Color successColor = Color(0xFF66BB6A);    // Emerald Green

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textSecondaryColor,
        ),
      ),

      // Input Decoration Theme (Premium glassmorphic styled inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.6)),
        labelStyle: const TextStyle(color: textSecondaryColor),
        
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textSecondaryColor.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),

      // Elevated Button Theme (Smooth animations, rounded corners)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimaryColor,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
