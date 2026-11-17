/// App Theme Configuration - Light & Dark Mode
/// Complete ThemeData setup for Material 3 design

import 'package:flutter/material.dart';
import 'design_system.dart';

class AppTheme {
  /// Light Mode Theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.white,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.gray50,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        centerTitle: false,
        titleTextStyle: AppTypography.headingLarge.copyWith(
          color: AppColors.gray900,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.gray400,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.gray600,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.gray900),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.gray900),
        headlineSmall: AppTypography.headingXL.copyWith(color: AppColors.gray900),
        titleLarge: AppTypography.headingLarge.copyWith(color: AppColors.gray900),
        titleMedium: AppTypography.headingMedium.copyWith(color: AppColors.gray800),
        titleSmall: AppTypography.headingSmall.copyWith(color: AppColors.gray700),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.gray800),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.gray700),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.gray600),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.gray900),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.gray800),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.gray700),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: AppSpacing.lg,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.gray800),
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 8,
        shape: const CircleBorder(),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearMinHeight: 4,
      ),
    );
  }

  /// Dark Mode Theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.darkBg,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.darkBg,
        error: Color(0xFFFF6B6B),
        onError: AppColors.darkBg,
        surface: AppColors.darkBgSecondary,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.darkBg,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkBgSecondary,
        foregroundColor: AppColors.darkText,
        centerTitle: false,
        titleTextStyle: AppTypography.headingLarge.copyWith(
          color: AppColors.darkText,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkBgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBgTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: Color(0xFFFF6B6B),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.darkBg,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkText),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkText),
        headlineSmall: AppTypography.headingXL.copyWith(color: AppColors.darkText),
        titleLarge: AppTypography.headingLarge.copyWith(color: AppColors.darkText),
        titleMedium: AppTypography.headingMedium.copyWith(color: AppColors.darkTextSecondary),
        titleSmall: AppTypography.headingSmall.copyWith(color: AppColors.darkTextSecondary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextSecondary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkBorder),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkText),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkBorder),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: AppSpacing.lg,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBgTertiary,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.darkText),
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.darkBg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.darkBg,
        elevation: 8,
        shape: const CircleBorder(),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearMinHeight: 4,
      ),
    );
  }
}
