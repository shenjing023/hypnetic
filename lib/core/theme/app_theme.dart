import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6B4AA3);
  static const Color secondaryColor = Color(0xFFF8BBD0);
  static const Color backgroundColor = Color(0xFF2C1B47);
  static const Color surfaceColor = Color(0xFF3D2960);
  static const Color textColor = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: secondaryColor,
        overlayColor: secondaryColor.withOpacity(0.3),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12.0,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 24.0,
        ),
      ),
    );
  }
}
