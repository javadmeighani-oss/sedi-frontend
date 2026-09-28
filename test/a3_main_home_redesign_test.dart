import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/utils/brand_name.dart';
import 'package:sedi_app/features/gate3_interactive/models/gate3_interaction_state.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_top_navigation_tray.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_brain_orb.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_orb_presence.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_presence_tokens.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('A3 home source: collapsed tray, four destinations, chat Expanded', () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    final orb = _read(
      'lib/features/gate3_interactive/presentation/widgets/sedi_brain_orb.dart',
    );
    final presence = _read(
      'lib/features/gate3_interactive/presentation/widgets/sedi_orb_presence.dart',
    );
    final vis = _read(
      'lib/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart',
    );
    final row = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
    );

    expect(page.contains('_topTrayExpanded = false'), isTrue);
    expect(page.contains('Gate3TopNavigationTray'), isTrue);
    expect(page.contains('Gate3MainIconRow'), isTrue);
    expect(page.contains('SediOrbPresence'), isTrue);
    expect(page.contains('horizontal: SediOrbPresence.horizontalInset'), isTrue);
    expect(page.contains('Expanded('), isTrue);
    expect(page.contains('Gate3Composer'), isTrue);
    expect(page.contains('Gate3ReturnToLatestButton'), isTrue);
    expect(page.contains('Gate3MemoryConsentInvitation'), isFalse);
    expect(page.contains('late final ChatController _controller'), isTrue);
    expect(page.contains('_topTrayExpanded'), isTrue);
    expect(page.contains('sendUserMessage(widget.initialDraft'), isFalse);
    expect(page.contains('Positioned(') && page.contains('SediOrbPresence'), isTrue);
    expect(RegExp(r'Positioned[\s\S]*SediOrbPresence').hasMatch(page), isFalse);

    expect(row.contains('profileTitle'), isTrue);
    expect(row.contains('lifestyle'), isTrue);
    expect(row.contains('gadgets'), isTrue);
    expect(row.contains('notifications'), isTrue);
    expect(row.contains('unreadNotificationCount'), isTrue);
    expect(row.contains('healthCare'), isFalse);

    expect(orb.contains('SediFrequencyRingPainter'), isFalse);
    expect(orb.contains('SediOrbTexturePainter'), isFalse);
    expect(orb.contains('sediOrbBrandLatin'), isTrue);
    expect(SediPresenceTokens.orbWidthFactor, closeTo(0.204, 0.0001));
    expect(SediPresenceTokens.orbMinDiameter, closeTo(73.6, 0.0001));
    expect(SediPresenceTokens.orbMaxDiameter, closeTo(83.2, 0.0001));
    expect(SediPresenceTokens.barOpacityScale, closeTo(1.20, 0.0001));
    expect(presence.contains('horizontalInset * 2'), isFalse);
    expect(presence.contains('maxW - SediOrbPresence.horizontalInset'), isFalse);

    final tray = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_top_navigation_tray.dart',
    );
    expect(tray.contains('handleHeight = 44'), isTrue);
    expect(tray.contains('visualSize = 18 * 1.30'), isTrue);
    expect(tray.contains('strokeWidth = 1.5 * 1.10'), isTrue);
    expect(tray.contains('size: 18'), isFalse);
    expect(Gate3TopNavigationTray.handleHeight, 44);

    expect(
      'SediHorizontalResonanceVisualizer'.allMatches(presence).length,
      1,
    );
    expect(presence.contains('orbBreathingGap'), isFalse);

    expect(vis.contains('barCount = 98'), isTrue);
    expect(vis.contains('amplitudeScale'), isTrue);
    expect(vis.contains('SediPresenceTokens.amplitudeScale'), isTrue);
    expect(vis.contains('height = SediPresenceTokens.visualizerHeight'), isTrue);
    expect(vis.contains('phaseSpeed = 0.85'), isTrue);
    expect(vis.contains('barOpacityScale'), isTrue);
    expect(orb.contains('d * 0.34'), isTrue);
    expect(orb.contains('0.80'), isFalse);

    expect(sediOrbBrandLatin, 'Sedi.');
    expect(SediPresenceTokens.presenceGreen, const Color(0xFF86F83C));
    expect(SediPresenceTokens.amplitudeScale, 0.80);
    expect(SediHorizontalResonanceVisualizer.height, 52);
    expect(SediHorizontalResonanceVisualizer.barCount, 98);
    expect(vis.contains('audioResonanceShape'), isTrue);
    expect(vis.contains('peakCeiling'), isTrue);
    expect(vis.contains('centerDistance'), isTrue);
    expect(vis.contains('ecgShape'), isFalse);
    expect(vis.contains('heartbeatEnvelope'), isFalse);
    expect(vis.contains('QRS'), isFalse);
    expect(vis.contains('not I9'), isTrue);
    expect(vis.contains('Random('), isFalse);
    expect(vis.contains('random('), isFalse);
    expect(tray.contains('a3-top-tray-toggle'), isTrue);
    expect(tray.contains('easeOutCubic'), isTrue);
  });

  test('canonical destinations + EN/FA/AR tray labels + RTL', () {
    expect(Gate3Localization('en').isRtl, isFalse);
    expect(Gate3Localization('fa').isRtl, isTrue);
    expect(Gate3Localization('ar').isRtl, isTrue);
    expect(Gate3Localization('en').expandDestinations, isNotEmpty);
    expect(Gate3Localization('fa').expandDestinations, isNotEmpty);
    expect(Gate3Localization('ar').collapseDestinations, isNotEmpty);
    expect(Gate3Localization('en').profileTitle, isNotEmpty);
    expect(Gate3Localization('en').lifestyle, isNotEmpty);
    expect(Gate3Localization('en').gadgets, isNotEmpty);
    expect(Gate3Localization('en').notifications, isNotEmpty);
  });

  test('idle < listening < thinking < speaking; amplitude reduced ~20%', () {
    final idle = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.idle);
    final listening = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.listening);
    final thinking = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.thinking);
    final speaking = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.speaking);
    expect(idle < listening, isTrue);
    expect(listening < thinking, isTrue);
    expect(thinking < speaking, isTrue);
    expect(SediHorizontalResonanceVisualizer.amplitudeScale, closeTo(0.80, 0.01));
    expect(SediHorizontalResonanceVisualizer.height, 52);
    expect(SediHorizontalResonanceVisualizer.phaseSpeed, 0.85);
    expect(SediHorizontalResonanceVisualizer.barCount, 98);
    expect(SediHorizontalResonanceVisualizer.peakCeiling, closeTo(0.65, 0.001));
    expect(
      SediHorizontalResonanceVisualizer.peakCeiling,
      lessThan(SediHorizontalResonanceVisualizer.previousSpeakingPeak),
    );

    const phases = [0.00, 0.17, 0.41, 0.73];
    const pairs = [
      [0.05, 0.95],
      [0.12, 0.88],
      [0.20, 0.80],
      [0.31, 0.69],
      [0.42, 0.58],
    ];
    var maxMirrorDelta = 0.0;
    for (final phase in phases) {
      final center = SediHorizontalResonanceVisualizer.audioResonanceShape(
        0.50,
        phase,
      );
      expect(center, inInclusiveRange(0.0, 1.0));
      expect(
        SediHorizontalResonanceVisualizer.audioResonanceShape(0.50, phase),
        closeTo(center, 1e-12),
      );
      for (final pair in pairs) {
        final left = SediHorizontalResonanceVisualizer.audioResonanceShape(
          pair[0],
          phase,
        );
        final right = SediHorizontalResonanceVisualizer.audioResonanceShape(
          pair[1],
          phase,
        );
        expect(left, inInclusiveRange(0.0, 1.0));
        expect(right, closeTo(left, 1e-9));
        final delta = (left - right).abs();
        if (delta > maxMirrorDelta) maxMirrorDelta = delta;
      }
    }
    expect(maxMirrorDelta, lessThan(1e-9));

    const phase = 0.18;
    var maxStep = 0.0;
    var minVal = 1.0;
    var maxVal = 0.0;
    var prev = SediHorizontalResonanceVisualizer.audioResonanceShape(0.0, phase);
    minVal = prev;
    maxVal = prev;
    for (var i = 1; i <= 97; i++) {
      final x = i / 97;
      final next = SediHorizontalResonanceVisualizer.audioResonanceShape(x, phase);
      final step = (next - prev).abs();
      if (step > maxStep) maxStep = step;
      if (next < minVal) minVal = next;
      if (next > maxVal) maxVal = next;
      prev = next;
    }
    expect(maxStep, lessThan(0.12));
    expect(maxVal - minVal, greaterThan(0.20));

    final speakingCapped = SediHorizontalResonanceVisualizer.heightFactorFor(
      energy: speaking,
      envelope: 1.0,
      density: 1.0,
    );
    expect(speakingCapped, closeTo(SediHorizontalResonanceVisualizer.peakCeiling, 0.001));
    expect(speakingCapped, lessThan(SediHorizontalResonanceVisualizer.previousSpeakingPeak));
  });

  test('responsive orb diameter is 80% of prior tokens and clamped', () {
    expect(SediPresenceTokens.orbWidthFactor, closeTo(0.255 * 0.80, 0.0001));
    expect(SediPresenceTokens.orbMinDiameter, closeTo(92 * 0.80, 0.0001));
    expect(SediPresenceTokens.orbMaxDiameter, closeTo(104 * 0.80, 0.0001));
    expect(SediBrainOrb.diameterFor(400), closeTo(400 * 0.204, 0.01));
    expect(SediBrainOrb.diameterFor(200), SediBrainOrb.minDiameter);
    expect(SediBrainOrb.diameterFor(800), SediBrainOrb.maxDiameter);
    expect(SediPresenceTokens.barCountFor(400), inInclusiveRange(96, 100));
  });

  testWidgets('tray default collapsed; toggle shows then hides 4 destinations',
      (tester) async {
    var expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Gate3TopNavigationTray(
                    expanded: expanded,
                    onToggle: () => setState(() => expanded = !expanded),
                    expandLabel: 'Show destinations',
                    collapseLabel: 'Hide destinations',
                    child: Gate3MainIconRow(
                      onLifestyle: () {},
                      onGadgets: () {},
                      onNotifications: () {},
                      lang: 'en',
                      unreadNotificationCount: 3,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Gate3MainIconRow), findsNothing);
    expect(find.text('Profile'), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byType(Gate3MainIconRow), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Gadgets'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byType(Gate3MainIconRow), findsNothing);

    await tester.tap(find.byKey(const ValueKey('a3-top-tray-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byType(Gate3MainIconRow), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('a3-top-tray-semantics')),
          )
          .properties
          .label,
      'Hide destinations',
    );

    await tester.tap(find.byKey(const ValueKey('a3-top-tray-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byType(Gate3MainIconRow), findsNothing);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('a3-top-tray-semantics')),
          )
          .properties
          .label,
      'Show destinations',
    );
  });

  testWidgets('collapsed presence is higher and chat is taller than expanded',
      (tester) async {
    var expanded = false;
    late StateSetter setTray;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 640,
            child: StatefulBuilder(
              builder: (context, setState) {
                setTray = setState;
                return Column(
                  children: [
                    Gate3TopNavigationTray(
                      expanded: expanded,
                      onToggle: () {},
                      expandLabel: 'Show destinations',
                      collapseLabel: 'Hide destinations',
                      child: const SizedBox(height: 72, width: double.infinity),
                    ),
                    const SediOrbPresence(
                      state: Gate3InteractionState.idle,
                      lang: 'en',
                    ),
                    const Expanded(
                      child: ColoredBox(
                        color: Color(0xFFEEEEEE),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final collapsedPresence = tester.getRect(find.byType(SediOrbPresence));
    final collapsedChat = tester.getRect(find.byType(ColoredBox));

    setTray(() => expanded = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final expandedPresence = tester.getRect(find.byType(SediOrbPresence));
    final expandedChat = tester.getRect(find.byType(ColoredBox));

    expect(collapsedPresence.top, lessThan(expandedPresence.top));
    expect(collapsedChat.height, greaterThan(expandedChat.height));
  });

  testWidgets('presence renders one visualizer, no ring/texture, Latin Sedi.',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SediOrbPresence.horizontalInset,
              ),
              child: SediOrbPresence(
                state: Gate3InteractionState.speaking,
                lang: 'fa',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SediHorizontalResonanceVisualizer), findsOneWidget);
    expect(find.text('Sedi.'), findsOneWidget);
    expect(find.text('صدی'), findsNothing);
    final presenceRect = tester.getRect(find.byType(SediOrbPresence));
    final orbRect = tester.getRect(find.byType(SediBrainOrb));
    expect(presenceRect.width, closeTo(366, 0.5));
    expect(orbRect.center.dx, closeTo(presenceRect.center.dx, 0.5));
    expect(
      orbRect.width,
      inInclusiveRange(
        SediPresenceTokens.orbMinDiameter,
        SediPresenceTokens.orbMaxDiameter,
      ),
    );
    expect(
      tester.getSize(find.byType(SediHorizontalResonanceVisualizer)).height,
      52,
    );
  });

  testWidgets('handle tap target is at least 44dp with a compact arrow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate3TopNavigationTray(
            expanded: false,
            onToggle: () {},
            expandLabel: 'Show destinations',
            collapseLabel: 'Hide destinations',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(44));
    final chevron = find.descendant(
      of: find.byType(InkWell),
      matching: find.byType(CustomPaint),
    );
    expect(chevron, findsOneWidget);
    expect(tester.getSize(chevron).width, closeTo(18 * 1.30, 0.01));
    expect(tester.getSize(chevron).height, closeTo(18 * 1.30, 0.01));
  });
}
