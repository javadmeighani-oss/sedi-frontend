import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/gate3_interactive/models/gate3_interaction_state.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_living_echo.dart';

/// D-127 (Javad approved the Living Echo concept, 2026-10-27): the official logo only inside the sphere, a calmer user
/// bubble in the sphere's pistachio glass, heavier text, and no rotating-ring hologram on the icon pages.
void main() {
  testWidgets('hero is large and full strength; compact is a small header', (tester) async {
    Future<Size> sizeOf({required bool compact}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SediLivingEcho(
                state: Gate3InteractionState.idle,
                compact: compact,
                heroSize: 300,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(SediHologramOrb));
    }

    final hero = await sizeOf(compact: false);
    final small = await sizeOf(compact: true);
    expect(hero.width, closeTo(300 * SediLivingEcho.heroSphereFactor, 1));
    expect(small.width, closeTo(SediLivingEcho.compactSphere, 1));
    expect(
      SediLivingEcho.heightFor(compact: false, heroSize: 300),
      greaterThan(SediLivingEcho.heightFor(compact: true, heroSize: 300)),
    );
  });

  testWidgets('every state renders the sphere with the single official wordmark', (tester) async {
    for (final state in Gate3InteractionState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SediLivingEcho(state: state, compact: false, heroSize: 260),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SediHologramOrb), findsOneWidget);
    }
    expect(SediHologramOrb.logoAsset, 'assets/images/sedi_wordmark.png');
  });

  testWidgets('message text is heavier and the user bubble is pistachio glass', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MessageBubble(message: 'Sedi says', isSedi: true),
              MessageBubble(message: 'User says', isSedi: false),
            ],
          ),
        ),
      ),
    );
    final sedi = tester.widget<Text>(find.text('Sedi says'));
    final user = tester.widget<Text>(find.text('User says'));
    expect(sedi.style!.fontWeight, FontWeight.w600);
    expect(user.style!.fontWeight, FontWeight.w600);
    expect(user.style!.color, MessageBubble.userTextColor);
    final bubble = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .single;
    final deco = bubble.decoration as BoxDecoration;
    expect(deco.gradient, isA<LinearGradient>());
    expect((deco.gradient as LinearGradient).colors, MessageBubble.userBubbleGradient);
  });

  test('icon pages no longer carry the rotating-ring hologram', () {
    for (final path in const [
      'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
      'lib/features/gate3_interactive/presentation/pages/gate3_memory_page.dart',
      'lib/features/devices/presentation/pages/devices_page.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains('A3HologramHeader'), isFalse, reason: path);
    }
    expect(
      File('lib/features/gate3_interactive/presentation/widgets/a3_hologram_header.dart').existsSync(),
      isFalse,
    );
  });
}
