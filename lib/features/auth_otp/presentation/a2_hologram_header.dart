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

  const A2HologramHeader({
    super.key,
    required this.l10n,
    this.hero = false,
    this.state = Gate3InteractionState.idle,
  });

  @override
  Widget build(BuildContext context) {
    final orbD = hero ? 168.0 : 104.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: hero ? 28 : 8),
        SediHologramOrb(state: state, diameter: orbD),
        SizedBox(height: hero ? 44 : 30),
        if (hero) ...[
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                SediPalette.shell100,
                SediPalette.skin300,
                SediPalette.skin500,
              ],
              stops: [0.25, 0.75, 1.0],
            ).createShader(rect),
            child: Text(
              l10n.welcomeHeadline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
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
                color: SediPalette.shell300.withOpacity(0.85),
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
              _pill(l10n.welcomePromiseRemember, rose: true),
              _pill(l10n.welcomePromiseCare, rose: false),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }

  Widget _pill(String text, {required bool rose}) {
    final base = rose ? SediPalette.skin500 : SediPalette.pistachio500;
    final fg = rose ? SediPalette.skin300 : SediPalette.pistachio300;
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
