import 'package:flutter/material.dart';

import '../../features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../locale/sedi_locale_controller.dart';
import '../theme/sedi_fonts.dart';

/// Everything A3 needs to draw its first frame without a pop-in (Javad 2026-10-31: icons and the A3 home must appear at
/// once). A1 plays its logo for three seconds anyway, so this runs then: the wordmark that sits inside every Sedi sphere
/// is decoded into the image cache, and every text weight A3 uses is laid out once so the font files are already read.
/// Presentation only; every step is fail-open and runs once per app start.
class SediWarmup {
  SediWarmup._();

  static bool _started = false;

  /// Weights used by the app (see pubspec fonts).
  static const List<FontWeight> weights = <FontWeight>[
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ];

  static Future<void> run(BuildContext context) async {
    if (_started) return;
    _started = true;
    warmFonts(SediLocaleController.instance.languageCode);
    try {
      await precacheImage(const AssetImage(SediHologramOrb.logoAsset), context);
    } catch (_) {}
  }

  /// Lays out a short Persian + Latin + digits line in every weight of the language's family (reads the font files).
  static void warmFonts(String languageCode) {
    try {
      final family = SediFonts.familyFor(languageCode);
      final fallback = SediFonts.fallbackFor(languageCode);
      for (final w in weights) {
        TextPainter(
          text: TextSpan(
            text: 'صدی Sedi سلام abc ۱۲۳ 123',
            style: TextStyle(fontFamily: family, fontFamilyFallback: fallback, fontWeight: w, fontSize: 16),
          ),
          textDirection: TextDirection.rtl,
        ).layout();
      }
    } catch (_) {}
  }

  @visibleForTesting
  static void reset() => _started = false;
}
