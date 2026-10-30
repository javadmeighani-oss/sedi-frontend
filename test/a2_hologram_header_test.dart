import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_hologram_header.dart';
import 'package:sedi_app/features/auth_otp/presentation/otp_login_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';

/// A2 (Javad 2026-10-30): no circle-with-rings picture; Sedi's sphere with her wordmark, 10 % larger than it was.
void main() {
  Future<void> pump(WidgetTester tester, {required bool hero}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: A2HologramHeader(l10n: const OtpLoginLocalization('fa'), hero: hero, animate: false),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final hero in [true, false]) {
    testWidgets('${hero ? 'first step' : 'later steps'}: a ring-less sphere, 10 % larger than the old circle',
        (tester) async {
      await pump(tester, hero: hero);
      final orb = tester.widget<SediHologramOrb>(find.byType(SediHologramOrb));
      expect(orb.showRings, isFalse);
      expect(orb.showLogo, isTrue);
      final old = (hero ? 168.0 : 104.0) * 0.68; // the old circle itself, without its rings
      expect(orb.diameter, closeTo(old * 1.10, 0.001));
      expect(tester.getSize(find.byType(SediHologramOrb)).width, closeTo(old * 1.10, 0.5));
    });
  }

  test('the size rule', () {
    expect(A2HologramHeader.sphereDiameter(hero: true), closeTo(125.664, 0.001));
    expect(A2HologramHeader.sphereDiameter(hero: false), closeTo(77.792, 0.001));
  });
}
