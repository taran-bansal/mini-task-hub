import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from Figma
  static const Color primaryBackground = Color(0xFF212832);
  static const Color accentYellow = Color(0xFFFED36A);
  static const Color inputBackground = Color(0xFF455A64);
  static const Color secondaryText = Color(0xFF8CAAB9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color decorativeGold = Color(0xFFBC9434);

  // Text Styles
  static TextStyle get heading => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: white,
      );

  static TextStyle get bodyText => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: white,
      );

  static TextStyle get linkText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondaryText,
      );

  static TextStyle get brandText => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: white,
      );

  // Theme Data
  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: primaryBackground,
        colorScheme: const ColorScheme.dark(
          primary: accentYellow,
          secondary: decorativeGold,
          background: primaryBackground,
          surface: inputBackground,
        ),
        textTheme: TextTheme(
          headlineLarge: heading,
          bodyLarge: bodyText,
          bodyMedium: linkText,
          labelLarge: brandText,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: bodyText.copyWith(color: secondaryText),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentYellow,
            foregroundColor: Colors.black,
            textStyle: bodyText.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
}
