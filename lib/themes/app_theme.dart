import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const primaryColor = Color(0xFFFAF1E6); // Warm off-white
  static const accentColor = Color(0xFF6B8AFE); // Modern blue
  static const secondaryColor = Color(0xFFF9F6F2); // Light warm gray
  static const darkBackgroundColor = Color(0xFF1A1B26); // Deep navy
  static const darkCardBackgroundColor = Color(0xFF24283B); // Rich navy-gray

  // Semantic colors
  static const successColor = Color(0xFF4ADE80); // Vibrant green
  static const warningColor = Color(0xFFFBBF24); // Warm amber
  static const errorColor = Color(0xFFF87171); // Soft red
  static const infoColor = Color(0xFF60A5FA); // Bright blue

  // Security severity colors
  static const criticalColor = Color(0xFFEF4444); // Bright red
  static const highColor = Color(0xFFF97316); // Vibrant orange
  static const mediumColor = Color(0xFFEAB308); // Bright yellow
  static const lowColor = Color(0xFF22C55E); // Fresh green

  // Text colors
  static const textPrimaryColor = Color(0xFF1F2937); // Dark gray
  static const textSecondaryColor = Color(0xFF6B7280); // Medium gray
  static const textDarkPrimaryColor = Color(0xFFF3F4F6); // Light gray
  static const textDarkSecondaryColor = Color(0xFF9CA3AF); // Medium light gray

  // Card colors
  static const cardBackgroundColor = Colors.white;
  static const cardBackgroundDarkColor = Color(0xFF24283B);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF6B8AFE), // Modern blue
    Color(0xFF8B5CF6), // Rich purple
    Color(0xFFF87171), // Soft red
    Color(0xFF4ADE80), // Vibrant green
    Color(0xFFFBBF24), // Warm amber
    Color(0xFF60A5FA), // Bright blue
    Color(0xFFEC4899), // Vibrant pink
  ];

  // Gradient backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B8AFE), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Get light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: accentColor,
      secondary: Color(0xFF8B5CF6),
      error: errorColor,
      background: secondaryColor,
      surface: cardBackgroundColor,
    ),
    scaffoldBackgroundColor: secondaryColor,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: primaryColor,
      foregroundColor: textPrimaryColor,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBackgroundColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: cardBackgroundColor,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: darkBackgroundColor,
      contentTextStyle: TextStyle(color: textDarkPrimaryColor),
    ),
  );

  // Get dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      secondary: Color(0xFF8B5CF6),
      error: errorColor,
      background: darkBackgroundColor,
      surface: darkCardBackgroundColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: darkBackgroundColor,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDarkPrimaryColor,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: darkCardBackgroundColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: darkCardBackgroundColor,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: darkCardBackgroundColor,
      contentTextStyle: TextStyle(color: textDarkPrimaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: darkCardBackgroundColor,
    ),
  );
}
