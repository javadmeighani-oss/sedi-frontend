import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_attachment_flow.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_attachment_menu.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_top_navigation_tray.dart';

String _read(String path) => File(path).readAsStringSync();

/// Pilot V1 screen 1 (R-034, Javad 2026-10-29): 3D sphere + real wordmark, glass messages with every line the same
/// width, a liquid-glass composer with a bare paperclip, icon-only attach stack, glass top tray.
void main() {
  testWidgets('every line of Sedi\'s and the user\'s text is justified; Sedi sits in glass', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MessageBubble(message: 'Sedi says something', isSedi: true),
              MessageBubble(message: 'User says something', isSedi: false),
            ],
          ),
        ),
      ),
    );
    final sedi = tester.widget<Text>(find.text('Sedi says something'));
    final user = tester.widget<Text>(find.text('User says something'));
    expect(sedi.textAlign, TextAlign.justify);
    expect(user.textAlign, TextAlign.justify);
    // only Sedi's panel blurs what is behind it
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('the attach stack is icon only: three icons, no visible text, no sheet', (tester) async {
    final semantics = tester.ensureSemantics();
    final l10n = Gate3Localization('en');
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Gate3AttachmentMenu.show(
                  context,
                  'en',
                  flow: Gate3AttachmentFlow(),
                  onTalk: (_) {},
                  anchor: Rect.fromLTWH(300, 700, 48, 48),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.text(l10n.files), findsNothing);
    expect(find.text(l10n.photos), findsNothing);
    expect(find.text(l10n.camera), findsNothing);
    // accessibility still names them
    expect(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l10n.camera),
      findsOneWidget,
    );
    // one above the other
    final files = tester.getCenter(find.byIcon(Icons.insert_drive_file_outlined));
    final photos = tester.getCenter(find.byIcon(Icons.photo_library_outlined));
    final camera = tester.getCenter(find.byIcon(Icons.photo_camera_outlined));
    expect(files.dx, closeTo(photos.dx, 0.5));
    expect(photos.dx, closeTo(camera.dx, 0.5));
    expect(files.dy, lessThan(photos.dy));
    expect(photos.dy, lessThan(camera.dy));
    semantics.dispose();
  });

  test('the attach menu is no sheet and carries no text widget', () {
    final menu = _read('lib/features/gate3_interactive/presentation/widgets/gate3_attachment_menu.dart');
    expect(menu.contains('showModalBottomSheet'), isFalse);
    expect(menu.contains('Text('), isFalse);
    expect(menu.contains('ringSize = 53'), isTrue);
    expect(menu.contains('iconSize = 27'), isTrue);
  });

  test('composer: glass capsule, bare paperclip, 3D mic, justified typed text', () {
    final c = _read('lib/features/gate3_interactive/presentation/widgets/gate3_composer.dart');
    expect(c.contains('SediGlass.capsule'), isTrue);
    expect(c.contains('Icons.attach_file_rounded'), isTrue);
    expect(c.contains('bare: true'), isTrue);
    expect(c.contains('sphere: true'), isTrue);
    expect(c.contains('TextAlign.justify'), isTrue);
    expect(c.contains('_fieldKey'), isTrue); // the keyboard fix stays
    expect(c.contains('anchor: _attachRect()'), isTrue);
  });

  test('top tray: a glass pill when collapsed, a glass panel with tiles when open', () {
    final t = _read('lib/features/gate3_interactive/presentation/widgets/gate3_top_navigation_tray.dart');
    expect(t.contains('SediGlass.trayPanel'), isTrue);
    expect(t.contains('SediGlass.pill'), isTrue);
    expect(t.contains('a3-top-tray-toggle'), isTrue);
    expect(Gate3TopNavigationTray.expandedExtraHeight, 88);
    final b = _read('lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_button.dart');
    expect(b.contains('SediGlass.tile()'), isTrue);
    expect(b.contains('tileSize = 58'), isTrue);
  });

  test('the scene is a soft pistachio gradient, not a flat colour', () {
    final bd = _read('lib/features/gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart');
    expect(bd.contains('LinearGradient'), isTrue);
    expect(bd.contains('ColoredBox'), isFalse);
    final glass = _read('lib/core/theme/sedi_glass.dart');
    expect(glass.contains('0xFFE6EBCB'), isTrue);
    expect(glass.contains('0xFFC8D197'), isTrue);
  });

  test('the logo keeps the real wordmark at 68 % of the sphere', () {
    final orb = _read('lib/features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart');
    expect(orb.contains("logoAsset = 'assets/images/sedi_wordmark.png'"), isTrue);
    expect(orb.contains('logoWidthFactor = 0.68'), isTrue);
  });
}
