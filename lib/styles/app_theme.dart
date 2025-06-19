import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF64B5F6);
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  // Text Styles
  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        color: textPrimaryColor,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        color: textPrimaryColor,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        color: textSecondaryColor,
      );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: primaryColor),
        ),
      );

  // Card Styles
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Input Decoration
  static InputDecoration get inputDecoration => InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
} 