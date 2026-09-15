import 'package:flutter/material.dart';

/// Apple Health & Wellness Design System Colors
/// Inspired by high-end Cupertino aesthetics, luminous aurora meshes, and glassmorphism.
class AppColors {
  // Ethereal Aurora Gradients (Reference Aesthetic)
  static const Color auroraTop = Color(0xFFF6E8F6);      // Gentle lilac pink
  static const Color auroraMid = Color(0xFFFDE8EF);      // Soft blush rose
  static const Color auroraBottom = Color(0xFFEDEAFE);   // Airy lavender mist
  static const Color auroraSky = Color(0xFFE8F1FE);      // Dreamy sky tint
  static const Color background = Color(0xFFF7F5FA);    // Clean backdrop
  static const Color surface = Color(0xFFFAF8FD);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE7E3F0);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceCardDark = Color(0xFF1E1D2E);
  static const Color surfaceContainer = Color(0xFFF2EFF8);
  static const Color surfaceContainerLow = Color(0xFFF8F6FD);
  static const Color surfaceContainerHigh = Color(0xFFECE7F4);
  static const Color surfaceContainerHighest = Color(0xFFE4DEF0);

  // 1. Ambient Background Gradient (Holographic / Pearlescent Shifting)
  static const Color holoPeach = Color(0xFFFCE4EC);      // Pearlescent peach mist
  static const Color holoLavender = Color(0xFFEDE7F6);   // Soft lavender sheen
  static const Color holoIceCyan = Color(0xFFE1F5FE);    // Holographic soft ice blue
  static const Color holoBlush = Color(0xFFFFF3E0);      // Warm pearl blush
  static const Color holoSoftViolet = Color(0xFFF3E5F5); // Translucent violet

  // 2. Bold Aurora Moments (Reserved for Splash, Onboarding & Hero Displays)
  static const Color auroraHeroViolet = Color(0xFF4A148C);
  static const Color auroraHeroMagenta = Color(0xFF880E4F);
  static const Color auroraHeroTeal = Color(0xFF004D40);
  static const Color auroraHeroIndigo = Color(0xFF1A237E);
  static const Color auroraHeroIris = Color(0xFF6200EA);

  // 3. Apple Watch-Face-Style Stat Tiles (Dark Surface + Radial Glow)
  static const Color watchFaceDarkBg = Color(0xFF12111A);
  static const Color watchFaceDarkSurface = Color(0xFF1A1926);
  static const Color watchFaceBorder = Color(0x2EFFFFFF);
  static const Color watchHeartRate = Color(0xFFFF5252);   // Warm coral glow
  static const Color watchSleep = Color(0xFF5C6BC0);       // Deep indigo glow
  static const Color watchStress = Color(0xFFE040FB);      // Vivid magenta glow
  static const Color watchActivity = Color(0xFF00E676);    // Electric emerald glow
  static const Color watchSpO2 = Color(0xFF00E5FF);        // Cyan aura
  static const Color watchGlucose = Color(0xFFFFB300);     // Amber glow
  static const Color watchHydration = Color(0xFF29B6F6);   // Sky azure glow

  // Glassmorphism Tokens
  static const Color glassWhite = Color(0xB8FFFFFF);       // ~72% frosted white
  static const Color glassSurface = Color(0xD9FFFFFF);     // ~85% opaque white
  static const Color glassBorder = Color(0xA6FFFFFF);      // Crisp 65% white hairline
  static const Color glassBorderSubtle = Color(0x59FFFFFF);// 35% hairline
  static const Color glassHighlight = Color(0x66FFFFFF);   // Inner rim highlight
  static const Color glassDark = Color(0xD91E1D2E);        // Frosted dark pill

  // Primary Apple Palette
  static const Color primary = Color(0xFF5B4EEA);          // Apple wellness violet
  static const Color primaryContainer = Color(0xFF6E5DF6); // Vibrant iris
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF3F1FF);
  static const Color primaryFixed = Color(0xFFE5E2FF);
  static const Color primaryFixedDim = Color(0xFFC7C1FF);
  static const Color surfaceTint = Color(0xFF5B4EEA);

  // Typography & Text
  static const Color textPrimary = Color(0xFF1C1A27);      // Midnight ink
  static const Color textSecondary = Color(0xFF7E7C90);    // Warm slate
  static const Color textTertiary = Color(0xFFA6A4B7);     // Subtle caption
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFF4A485A);

  // Accents & Signals
  static const Color accentCoral = Color(0xFFFF5E7E);      // Attention / flagged
  static const Color accentTeal = Color(0xFF28C78B);       // Normal / verified / optimal
  static const Color accentGold = Color(0xFFFFB338);       // Warning / alert
  static const Color accentAmber = Color(0xFFFFB300);      // Glucose / metabolic amber
  static const Color accentPurple = Color(0xFF8B5CF6);     // AI neural vibe
  static const Color accentSky = Color(0xFF38BDF8);        // Hydration / breath
  static const Color accentRose = Color(0xFFF472B6);       // Warmth / heart

  // Mood Tracker Nodes
  static const Color moodEnergetic = Color(0xFF6E5DF6);
  static const Color moodCalm = Color(0xFF38BDF8);
  static const Color moodFocused = Color(0xFF8B5CF6);
  static const Color moodRadiant = Color(0xFFFB7185);
  static const Color moodRelaxed = Color(0xFF34D399);

  // Navigation & Borders
  static const Color navBackground = Color(0xFF1E1D2E);
  static const Color navDockBackground = Color(0xE6FFFFFF);
  static const Color outline = Color(0xFF8D8A9F);
  static const Color outlineVariant = Color(0xFFDDD9E8);

  // Apple-grade Soft Diffused Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(30, 26, 54, 0.045),
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color.fromRGBO(40, 30, 70, 0.05),
      blurRadius: 30,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.8),
      blurRadius: 0,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> dockShadow = [
    BoxShadow(
      color: Color.fromRGBO(30, 20, 60, 0.12),
      blurRadius: 36,
      spreadRadius: 0,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(20, 15, 40, 0.20),
      blurRadius: 36,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color.fromRGBO(110, 93, 246, 0.35),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> aiPulseShadow = [
    BoxShadow(
      color: Color.fromRGBO(110, 93, 246, 0.40),
      blurRadius: 24,
      spreadRadius: 2,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color.fromRGBO(56, 189, 248, 0.22),
      blurRadius: 36,
      spreadRadius: 4,
      offset: Offset(0, 10),
    ),
  ];
}
