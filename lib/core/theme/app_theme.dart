import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Central theme provider for HealthBase.
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary500,
        onPrimary: Colors.white,
        secondary: AppColors.secondary500,
        onSecondary: Colors.white,
        error: AppColors.statusUrgent,
        onError: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.neutral900,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.neutral900,
        elevation: 0.0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral900,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.neutral200),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.primary500, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.statusUrgent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.statusUrgent, width: 2.0),
        ),
        hintStyle: const TextStyle(color: AppColors.neutral400, fontSize: 14.0),
        labelStyle: const TextStyle(color: AppColors.neutral700, fontSize: 14.0),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelMedium: AppTypography.labelMedium,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        onPrimary: AppColors.neutral900,
        secondary: AppColors.secondaryLight,
        onSecondary: Colors.white,
        error: AppColors.statusUrgent,
        onError: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.neutral50,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.neutral50,
        elevation: 0.0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral50,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: const BorderSide(color: AppColors.neutral700),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtleDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.neutral700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.neutral700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.statusUrgent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: const BorderSide(color: AppColors.statusUrgent, width: 2.0),
        ),
        hintStyle: const TextStyle(color: AppColors.neutral500, fontSize: 14.0),
        labelStyle: const TextStyle(color: AppColors.neutral300, fontSize: 14.0),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.neutral50),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.neutral50),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.neutral50),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.neutral50),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.neutral100),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.neutral200),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.neutral300),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.neutral400),
      ),
    );
  }
}
