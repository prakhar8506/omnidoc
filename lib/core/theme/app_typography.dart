import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Serene Apple Health & Wellness Design System Typography
/// Provides const TextStyle constants for zero-overhead const widgets,
/// along with GoogleFonts newsreader serif typography for Apple editorial headlines.
class AppTypography {
  static bool get _isTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  // Apple Editorial Serif Headings
  static TextStyle get editorialLg {
    if (_isTest) {
      return const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.newsreader(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.8,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get editorialMd {
    if (_isTest) {
      return const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.newsreader(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.6,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get editorialSm {
    if (_isTest) {
      return const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.newsreader(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.4,
      color: AppColors.textPrimary,
    );
  }

  // Const TextStyles for full backwards compatibility and const performance
  static const TextStyle headlineLg = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 36 / 30,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 32 / 26,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLg = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 25 / 19,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 22 / 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 18 / 13,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );
}
