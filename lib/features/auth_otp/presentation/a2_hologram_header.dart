import 'package:flutter/material.dart';

import '../../../core/theme/sedi_palette.dart';
import '../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import 'otp_login_localization.dart';

/// A2 header: the approved hologram (+ welcome copy on the first step) above
/// the Shell form card. Presentation only; strings come from
/// [OtpLoginLocalization] (fa / ar / en).
class A2HologramHeader extends StatelessWidget {
  final OtpLoginLocalization l10n;

  /// First step (language): large hologram, headline, tagline and the three promises.
  final bool hero;
  final Gate3InteractionState state;

  /// false on short screens: static hologram frame (no Ticker), smaller header.
  final bool animate;

  const A2HologramHeader({
    super.key,
    required this.l10n,
    this.hero = false,
    this.state = Gate3InteractionState.idle,
    this.animate = true,
  });

  /// Edge of the old picture (the rings' footprint).
  static double oldFootprint({required bool hero}) => hero ? 168.0 : 104.0;

  /// The old circle itself, without its rings: the sphere was 68 % of the footprint.
  static double oldSphere({required bool hero}) => oldFootprint(hero: hero) * SediHologramOrb.sphereScaleWithRings;

  /// Javad 2026-10-30: the rings are gone; Sedi's glass sphere with her wordmark takes the place of the old CIRCLE
  /// (not of the rings' footprint) and is 10 % larger than that circle was.
  static const double sphereScale = 1.10;

  static double sphereDiameter({required bool hero}) => oldSphere(hero: hero) * sphereScale;

  @override
  Widget build(BuildContext context) {
    final orbD = sphereDiameter(hero: hero);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: hero ? 28 : 8),
        SediHologramOrb(state: state, diameter: orbD, showRings: false, animate: animate),
        SizedBox(height: hero ? 44 : 30),
        if (hero) ...[
          Text(
            l10n.welcomeHeadline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: SediPalette.charcoal950,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.welcomeTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.9,
                color: SediPalette.sageMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(l10n.welcomePromiseListen, rose: false),
              _pill(l10n.welcomePromiseRemember, rose: false),
              _pill(l10n.welcomePromiseCare, rose: false),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }

  Widget _pill(String text, {required bool rose}) {
    final base = rose ? SediPalette.skin700 : SediPalette.pistachio500;
    final fg = rose ? SediPalette.skin700 : SediPalette.pistachio900;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: base.withOpacity(0.16),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: base.withOpacity(0.38)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
