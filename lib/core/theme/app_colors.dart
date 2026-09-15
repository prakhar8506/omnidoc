import 'package:flutter/material.dart';

/// Serene Clinical Design System Colors
class AppColors {
  // Base Surface & Backgrounds
  static const Color background = Color(0xFFEAEBF5);
  static const Color surface = Color(0xFFEAEBF5);
  static const Color surfaceBright = Color(0xFFF9F9FF);
  static const Color surfaceDim = Color(0xFFD8D9E3);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceCardDark = Color(0xFF17181F);
  static const Color surfaceContainer = Color(0xFFECEDF7);
  static const Color surfaceContainerLow = Color(0xFFF2F3FD);
  static const Color surfaceContainerHigh = Color(0xFFE6E7F1);
  static const Color surfaceContainerHighest = Color(0xFFE1E2EC);

  // Primary Palette
  static const Color primary = Color(0xFF0040E0);
  static const Color primaryContainer = Color(0xFF2E5BFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFEFEFFF);
  static const Color primaryFixed = Color(0xFFDDE1FF);
  static const Color primaryFixedDim = Color(0xFFB8C3FF);
  static const Color surfaceTint = Color(0xFF124AF0);

  // Typography & Text
  static const Color textPrimary = Color(0xFF16181D);
  static const Color textSecondary = Color(0xFF8D909C);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFF434656);

  // Accents & Signals
  static const Color accentCoral = Color(0xFFFF6B81); // Attention / flagged
  static const Color accentTeal = Color(0xFF4FD1C5);  // Normal / verified / optimal
  static const Color accentGold = Color(0xFFFFC94A);  // Warning / pending
  static const Color accentPurple = Color(0xFF8B5CF6);// AI neural vibe
  
  // Navigation & Borders
  static const Color navBackground = Color(0xFF16181D);
  static const Color outline = Color(0xFF747688);
  static const Color outlineVariant = Color(0xFFC4C5D9);
  
  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(20, 20, 40, 0.06),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(20, 20, 40, 0.18),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color.fromRGBO(46, 91, 255, 0.35),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
  
  static const List<BoxShadow> aiPulseShadow = [
    BoxShadow(
      color: Color.fromRGBO(46, 91, 255, 0.45),
      blurRadius: 20,
      spreadRadius: 2,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(79, 209, 197, 0.25),
      blurRadius: 30,
      spreadRadius: 4,
      offset: Offset(0, 8),
    ),
  ];
}
