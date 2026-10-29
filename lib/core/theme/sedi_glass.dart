import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Pilot V1 "liquid glass" language (R-034, Javad 2026-10-29): see-through layers lifted off the page by a blur,
/// a light edge and a soft shadow; one pistachio 3D sphere control per screen; thin-line icons.
///
/// Presentation only: no logic. Colours are the pistachio / sage family of [SediPalette]; white is only light.
class SediGlass {
  SediGlass._();

  /// Soft pistachio page: a vertical gradient (replaces the flat Soft Sage page on the chat scene).
  static const List<Color> pageGradient = [
    Color(0xFFE6EBCB),
    Color(0xFFD6DDB0),
    Color(0xFFC8D197),
  ];
  static const List<double> pageStops = [0.0, 0.52, 1.0];

  /// Deep olive used for thin icon strokes and labels on glass.
  static const Color ink = Color(0xFF33410F);
  static const Color inkDeep = Color(0xFF243008);

  /// Soft olive shadow tint (72,85,31).
  static const Color _shadow = Color(0xFF48551F);

  static Color _white(double opacity) => Colors.white.withOpacity(opacity);

  /// Blurs what is behind [child] inside [radius] (the glass effect).
  static Widget blur({
    required BorderRadius radius,
    required Widget child,
    double sigma = 14,
  }) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  /// Sedi's message panel: almost fully transparent, separated from the page by its light edge and shadow.
  static BoxDecoration messagePanel(BorderRadius radius) {
    return BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_white(0.34), _white(0.10)],
      ),
      border: Border.all(color: _white(0.62)),
      boxShadow: [
        BoxShadow(
          color: _shadow.withOpacity(0.13),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// The composer capsule and other large floating glass surfaces.
  static BoxDecoration capsule(BorderRadius radius) {
    return BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_white(0.62), _white(0.26)],
      ),
      border: Border.all(color: _white(0.78)),
      boxShadow: [
        BoxShadow(
          color: _shadow.withOpacity(0.20),
          blurRadius: 34,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  /// The top tray panel (drops from the top edge).
  static BoxDecoration trayPanel(BorderRadius radius) {
    return BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_white(0.58), _white(0.26)],
      ),
      border: Border(
        left: BorderSide(color: _white(0.82)),
        right: BorderSide(color: _white(0.82)),
        bottom: BorderSide(color: _white(0.82)),
      ),
      boxShadow: [
        BoxShadow(
          color: _shadow.withOpacity(0.22),
          blurRadius: 38,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  /// The small pill that holds the tray chevron.
  static BoxDecoration pill({bool strong = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: strong ? [_white(0.78), _white(0.40)] : [_white(0.66), _white(0.28)],
      ),
      border: Border.all(color: _white(0.85)),
      boxShadow: [
        BoxShadow(
          color: _shadow.withOpacity(0.16),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// One destination tile of the top tray.
  static BoxDecoration tile() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_white(0.78), _white(0.30)],
      ),
      border: Border.all(color: _white(0.9)),
      boxShadow: [
        BoxShadow(
          color: _shadow.withOpacity(0.16),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// A round pistachio 3D glass control (the mic / send button): light from the top left, deeper rim, soft glow.
  static BoxDecoration pistachioSphere() {
    return const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(-0.32, -0.48),
        radius: 1.0,
        colors: [
          Color(0xFFF6FBD6),
          Color(0xFFCFE27C),
          Color(0xFFA9C648),
          Color(0xFF7F9E32),
        ],
        stops: [0.0, 0.36, 0.78, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x57608022),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  /// A hairline light ring with no fill of its own: the bare-icon look of the attach buttons.
  static BoxDecoration lightRing() {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: _white(0.12),
      border: Border.all(color: _white(0.9), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: _shadow.withOpacity(0.16),
          spreadRadius: 1,
        ),
      ],
    );
  }
}
