import 'package:flutter/material.dart';

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
  static const Color pistachioGreen = Color(0xFF8BC34A);

  /// خاکستری متال – حالت‌های خنثی و inactive
  static const Color metalGrey = Color(0xFF9E9E9E);

  /// مشکی – متن و آیکن فعال
  static const Color primaryBlack = Color(0xFF111111);

  /// سفید – بک‌گراند اصلی
  static const Color backgroundWhite = Color(0xFFFFFFFF);
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
