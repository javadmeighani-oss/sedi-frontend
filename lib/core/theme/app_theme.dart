import 'package:flutter/material.dart';

import 'sedi_palette.dart';

/// ============================================
/// AppTheme - هویت بصری صدی
/// ============================================
///
/// RESPONSIBILITY:
/// - فقط رنگ‌ها، radius، shadow
/// - بدون UI widget
/// - بدون logic
/// ============================================
class AppTheme {
  AppTheme._(); // جلوگیری از ساخت instance

  // ===============================
  // Brand Colors (Sedi Identity)
  // ===============================

  /// سبز پسته‌ای – هویت اصلی صدی
  static const Color pistachioGreen = SediPalette.pistachio500;

  /// خاکستری متال – حالت‌های خنثی و inactive
  static const Color metalGrey = SediPalette.charcoal500;

  /// مشکی – متن و آیکن فعال
  static const Color primaryBlack = SediPalette.charcoal950;

  /// سفید – بک‌گراند اصلی
  static const Color backgroundWhite = SediPalette.shell100;
  static const Color dangerRed = Color(0xFFD32F2F);

  // ===============================
  // Semantic Colors
  // ===============================
  static const Color primary = primaryBlack;
  static const Color background = backgroundWhite;
  static const Color surface = backgroundWhite;

  static const Color textPrimary = primaryBlack;
  static const Color textSecondary = metalGrey;

  static const Color iconInactive = metalGrey;
  static const Color iconActive = primaryBlack;

  static const Color borderInactive = metalGrey;
  static const Color borderActive = primaryBlack;

  /// Gate 2 — light gray input fill
  static const Color inputFillLight = SediPalette.shell300;

  /// Gate 2 — very light placeholder text
  static const Color placeholderLight = SediPalette.shell500;

  /// Gate 2 — selected language button fill
  static const Color languageSelectedFill = SediPalette.shell300;

  /// Gate 2 — disabled action button
  static const Color buttonDisabled = SediPalette.shell500;

  // ===============================
  // Gate 2 Luxury Palette
  // ===============================
  static const Color gate2WarmBackground = SediPalette.shell100;
  /// A2 page canvas — Charcoal 950 hologram scene (the form card stays Shell).
  static const Color a2PageBackground = SediPalette.charcoal950;
  static const Color gate2CardWhite = SediPalette.shell100;
  static const Color gate2InputFill = SediPalette.shell300;
  static const Color gate2ButtonActive = SediPalette.charcoal950;
  /// Gate 2 primary CTA / accent — Pistachio 700 (Palette v1).
  static const Color gate2ButtonOlive = SediPalette.pistachio700;
  static const Color gate2ButtonDisabled = SediPalette.shell300;
  static const Color gate2TextDisabled = SediPalette.charcoal500;
  static const Color gate2Placeholder = SediPalette.charcoal500;
  static const Color gate2TextPrimary = SediPalette.charcoal950;
  static const Color gate2TextMuted = SediPalette.charcoal500;
  static const Color gate2BorderSubtle = SediPalette.shell500;

  // ===============================
  // Intro (A1) — Birth of Sedi
  // ===============================
  /// Deep night sky behind the horizon emergence.
  static const Color introNightSky = Color(0xFF0A0E14);

  /// Mid-atmosphere tone between sky and horizon.
  static const Color introAtmosphere = Color(0xFF1A2332);

  /// Soft horizon glow (calm olive-earth).
  static const Color introHorizonGlow = Color(0xFF3D5A40);

  /// Emergence accent aligned with brand olive CTA.
  static const Color introEmergenceAccent = Color(0xFF6F7F3A);

  /// Logo / wordmark emphasis during final born state.
  static const Color introLogoEmphasis = Color(0xFF6F7F3A);

  /// Subtle overlay while startup/session work finishes.
  static const Color introOverlaySubtle = Color(0x660A0E14);

  /// Soft status text on intro (availability / loading).
  static const Color introStatusText = Color(0xB3FFFFFF);

  /// Fully transparent — InkWell/Material wrappers with no fill.
  static const Color surfaceTransparent = Color(0x00000000);

  static const double gate2RadiusCard = 22;
  static const double gate2RadiusInput = 14;

  /// Shared A2 control / CTA widths (dp). Narrow screens use available width.
  static const double a2CompactControlMax = 300;
  static const double a2PrimaryCtaMax = 360;
  static const double a2ReadableContentMax = 360;
  static const double a2PrimaryCtaHeight = 52;
  static const double a2PrimaryCtaFontSize = 18;
  static const double a2ControlFontSize = 16;

  // ===============================
  // Gate 3 Premium Palette
  // ===============================
  /// Gate 3 — soft pale olive-green background (premium, calm; avoid pure white).
  static const Color gate3PaleOliveBackground = SediPalette.shell300;

  /// I9 STABLE / calm positive status (olive; not clinical “safe”).
  static const Color statusStableOlive = SediPalette.pistachio700;

  /// I9 UNSTABLE_OR_CHANGED — warning amber (never danger red).
  static const Color statusChangeAmber = Color(0xFFC49A3C);

  /// I9 INSUFFICIENT_DATA — neutral muted.
  static const Color statusNeutralMuted = SediPalette.charcoal500;

  static const List<BoxShadow> gate2CardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  // ===============================
  // Radius
  // ===============================

  static const double radiusSmall = 8;
  static const double radiusMedium = 14;
  static const double radiusLarge = 18;

  // ===============================
  // Shadows (مینیمال)
  // ===============================

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000), // مشکی با opacity کم
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // ===============================
  // Typography
  // ===============================
  static const TextStyle titleLarge = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleMedium = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyPrimary = TextStyle(
    color: textPrimary,
    fontSize: 14,
  );

  static const TextStyle bodySecondary = TextStyle(
    color: textSecondary,
    fontSize: 14,
  );

  static const TextStyle caption = TextStyle(
    color: textSecondary,
    fontSize: 12,
  );
}
