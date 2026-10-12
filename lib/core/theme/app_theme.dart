import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.accentCoral,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shadowColor: const Color.fromRGBO(30, 26, 54, 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorderSubtle, width: 1),
        ),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: AppTypography.headlineLg,
        headlineMedium: AppTypography.headlineMd,
        titleLarge: AppTypography.titleLg,
        titleMedium: AppTypography.titleMd,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        labelMedium: AppTypography.labelMd,
        labelSmall: AppTypography.labelSm,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    const ink = Color(0xFFF4F2FA);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF101218),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryContainer,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        surface: Color(0xFF1C1E2A),
        onSurface: ink,
        surfaceContainerHighest: Color(0xFF2A2C3A),
        error: AppColors.accentCoral,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      textTheme: textTheme.apply(bodyColor: ink, displayColor: ink),
    );
  }
}
