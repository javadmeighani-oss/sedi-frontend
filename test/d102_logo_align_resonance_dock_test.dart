import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/gate3_interactive/models/gate3_interaction_state.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_resonance_dock.dart';

/// D-102 (Javad's phone test): Sedi's logo is level with her text and the typing dots, and the resonance is docked
/// above the composer at about half the width.
void main() {
  testWidgets('Sedi logo centre is level with the first line of her text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MessageBubble(message: 'Hello Javad', isSedi: true),
          ),
        ),
      ),
    );
    final logo = tester.getRect(find.byType(SediHologramOrb));
    final text = tester.getRect(find.text('Hello Javad'));
    expect(logo.height, closeTo(MessageBubble.sediLogoDiameter, 0.5));
    expect(logo.center.dy, closeTo(text.center.dy, 1.0));
  });

  testWidgets('a long Sedi message keeps the logo level with its FIRST line',
      (tester) async {
    final long = List.filled(40, 'word').join(' ');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MessageBubble(message: long, isSedi: true),
          ),
        ),
      ),
    );
    final logo = tester.getRect(find.byType(SediHologramOrb));
    final text = tester.getRect(find.text(long));
    // First line box = 15 * 1.45; the text block starts after the inset.
    final firstLineCentre = text.top + 15 * 1.45 / 2;
    expect(logo.center.dy, closeTo(firstLineCentre, 1.0));
  });

  testWidgets('typing dots stay level with the logo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MessageBubble(message: '', isSedi: true, showTyping: true),
          ),
        ),
      ),
    );
    final logo = tester.getRect(find.byType(SediHologramOrb));
    final dots = tester.getRect(find.byType(Row).last);
    expect(logo.center.dy, closeTo(dots.center.dy, 1.0));
  });

  test('text inset follows the logo and line metrics', () {
    expect(MessageBubble.sediTextTopInset,
        closeTo((34 - 15 * 1.45) / 2, 0.001));
  });

  testWidgets('resonance dock is centred and about half the width',
      (tester) async {
    for (final state in Gate3InteractionState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 400,
                child: SediResonanceDock(state: state),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final bars = tester.getRect(find.byType(SediHorizontalResonanceVisualizer));
      expect(bars.width, closeTo(400 * SediResonanceDock.widthFactor, 0.5));
      expect(bars.height, closeTo(SediResonanceDock.height, 0.5));
      final dock = tester.getRect(find.byType(SediResonanceDock));
      expect(bars.center.dx, closeTo(dock.center.dx, 0.5));
    }
  });

  test('A3 page docks the resonance above the composer, hologram alone behind', () {
    final page = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    ).readAsStringSync();
    expect(page.contains('withResonance: false'), isTrue);
    final dock = page.indexOf('SediResonanceDock(');
    final composer = page.indexOf('Gate3Composer(');
    expect(dock, greaterThan(0));
    expect(dock, lessThan(composer));
  });
}
