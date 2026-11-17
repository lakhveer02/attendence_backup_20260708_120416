import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Safe text styles with fallback to system fonts if Google Fonts fail
class AppTextStyles {
  AppTextStyles._();

  /// Get Poppins font with fallback
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    try {
      return GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (e) {
      // Fallback to system font
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFamily: '.AppleSystemUIFont', // macOS system font
      );
    }
  }

  /// Get Inter font with fallback
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    } catch (e) {
      // Fallback to system font
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFamily: '.AppleSystemUIFont', // macOS system font
      );
    }
  }
}
