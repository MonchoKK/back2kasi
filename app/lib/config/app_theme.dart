// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/**
 * Design system tokens and ThemeData for Back2Kasi.
 *
 * <p>Implements the Emerald Dark Identity for Back2Kasi marketplace:
 * - Brand Primary: Emerald Green (#10B981)
 * - Success: Emerald (#10B981)
 * - Accent: Warm Amber (#F59E0B)
 * - Deep Background: Charcoal Obsidian (#0D0E15)
 * - Surface / Cards: Rich Slate Dark (#161922)
 * - Primary Text: Crisp Off-White (#F8FAFC)
 * - Secondary Text: Muted Slate (#94A3B8)
 * - Borders: Subtle Dark Slate (#262D3D)
 *
 * Typography uses Inter with strict scale hierarchy.</p>
 */
class AppTheme {
  // Brand Colors
  static const Color brandColor = Color(0xFF10B981); // Emerald 500 (Vibrant on dark)
  static const Color primaryColor = brandColor;
  static const Color successColor = Color(0xFF10B981); // Emerald 500
  static const Color accentColor = Color(0xFFF59E0B);  // Amber 500
  static const Color darkColor = Color(0xFF0D0E15);    // Deep dark

  // Interface Neutrals (Emerald Dark Mode)
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFF0D0E15); // Charcoal Obsidian
  static const Color surfaceColor = Color(0xFF161922);    // Rich Slate Dark Card Surface
  static const Color cardColor = surfaceColor;
  static const Color textPrimaryColor = Color(0xFFF8FAFC); // Crisp Off-White / Slate 50
  static const Color darkTextColor = textPrimaryColor;     // Forward/backward compatible alias
  static const Color textSecondaryColor = Color(0xFF94A3B8); // Slate 400
  static const Color secondaryTextColor = textSecondaryColor; // Forward/backward compatible alias
  static const Color borderColor = Color(0xFF262D3D);    // Subtle Dark Slate Border
  static const Color errorColor = Color(0xFFEF4444);      // Red 500

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

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.40),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// The primary Emerald Dark Theme
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: darkColor,
        onSecondary: white,
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

      // Card Theme (16px corner radius, dark slate background, subtle border)
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),

      // Input Decoration Theme (52-56px height, rounded corners, subtle dark border)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textSecondaryColor.withOpacity(0.6), fontSize: 14),
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
          foregroundColor: darkColor,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size.fromHeight(50),
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

  /// Alias returning darkTheme to keep the experience consistently dark
  static ThemeData get lightTheme => darkTheme;
}
