// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/**
 * Design system tokens and ThemeData for Back2Kasi.
 *
 * <p>Implements the Emerald + Warm Ivory + Charcoal + Gold Identity:
 * - Brand Identity: Emerald (#059669)
 * - Background: Warm Ivory (#F8F5EE)
 * - Typography & Dark Surfaces: Charcoal (#252B27)
 * - Premium Accents: Champagne Gold (#D6A84F)
 * - Cards & Elevated Surfaces: Crisp White (#FFFFFF)
 * - Secondary Text: Muted Charcoal (#5C6660)
 * - Borders: Soft Warm Ivory Border (#E7E2D6)
 *
 * Typography uses Inter with strict scale hierarchy.</p>
 */
class AppTheme {
  // Brand Colors
  static const Color brandColor = Color(0xFF059669);    // Emerald 600
  static const Color emerald = brandColor;              // Emerald brand alias
  static const Color primaryColor = brandColor;
  static const Color successColor = Color(0xFF059669);  // Emerald 600
  static const Color accentColor = Color(0xFFD6A84F);   // Champagne Gold
  static const Color goldColor = accentColor;           // Champagne Gold alias
  static const Color charcoalColor = Color(0xFF252B27); // Charcoal
  static const Color darkColor = charcoalColor;         // Charcoal alias

  // Interface Neutrals (Warm Ivory System)
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF8F5EE); // Warm Ivory
  static const Color surfaceColor = Color(0xFFFFFFFF);    // Crisp White Card Surface
  static const Color cardColor = surfaceColor;
  static const Color textPrimaryColor = Color(0xFF252B27); // Charcoal Text
  static const Color darkTextColor = textPrimaryColor;     // Forward/backward compatible alias
  static const Color textSecondaryColor = Color(0xFF5C6660); // Muted Charcoal (WCAG AAA)
  static const Color secondaryTextColor = textSecondaryColor; // Forward/backward compatible alias
  static const Color borderColor = Color(0xFFE7E2D6);    // Warm Ivory Border
  static const Color errorColor = Color(0xFFDC2626);      // Red 600

  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Corner Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusPill = 999.0;

  // Box Shadows (Warm Charcoal Tints)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF252B27).withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF252B27).withOpacity(0.09),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ];

  /// The primary Emerald + Warm Ivory Theme
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: white,
        onSecondary: charcoalColor,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        onError: white,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),

      // Text Theme matching Back2Kasi typography guidelines
      textTheme: baseTextTheme.copyWith(
        // Screen headings (24-28px bold)
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: -0.5,
        ),
        // Section headings (18-20px semibold)
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.3,
        ),
        // Card titles (16px semibold)
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        // Body text (14-16px)
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
        // Supporting text (12-13px)
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),

      // Card Theme (16px corner radius, white surface, warm ivory border)
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),

      // Input Decoration Theme (52-56px height, rounded corners, subtle warm border)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textSecondaryColor.withOpacity(0.7), fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondaryColor, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
      ),

      // Elevated Button Theme (48-52px height, rounded corners, emerald primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: white,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Theme alias
  static ThemeData get darkTheme => lightTheme;
}
