import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.textDark,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.expenseRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.expenseRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMedium),
        hintStyle: const TextStyle(color: AppColors.textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textLight,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutralGreyLight,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          color: AppColors.textMedium,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textMedium, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textLight, fontSize: 12),
        labelLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
