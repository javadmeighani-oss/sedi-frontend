import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_composer.dart';

Gate3Composer _composer({required bool rtl, double? maxFieldHeight}) {
  return Gate3Composer(
    placeholder: rtl ? 'صحبت با صدی' : 'Talk to Sedi',
    lang: rtl ? 'fa' : 'en',
    isRtl: rtl,
    isRecording: false,
    recordingTime: '00:00',
    maxFieldHeight: maxFieldHeight,
    onListeningChanged: (_) {},
    onSendText: (_) {},
    onStartRecording: () {},
    onStopRecordingAndSend: () {},
  );
}

Future<void> _pump(WidgetTester tester, Gate3Composer composer) async {
  tester.view.physicalSize = const Size(720, 1400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: composer),
      ),
    ),
  );
  await tester.pump();
}

Finder _clip() => find.byIcon(Icons.attach_file_rounded);
Finder _mic() => find.byIcon(Icons.mic_rounded);
Finder _send() => find.byIcon(Icons.arrow_upward_rounded);

/// Javad 2026-10-30: while typing the paperclip and the send button sit BELOW the text, for any number of lines,
/// and the composer never outgrows the room the keyboard leaves.
void main() {
  for (final rtl in [true, false]) {
    final tag = rtl ? 'RTL' : 'LTR';

    testWidgets('$tag empty box: one row, placeholder level with the paperclip and the mic', (tester) async {
      await _pump(tester, _composer(rtl: rtl));
      final field = tester.getRect(find.byType(TextField));
      expect(tester.getCenter(_clip()).dy, closeTo(tester.getCenter(_mic()).dy, 1));
      expect(tester.getCenter(find.byType(TextField)).dy, closeTo(tester.getCenter(_mic()).dy, 3));
      expect(field.height, lessThan(60));
    });

    testWidgets('$tag from the first character the buttons are below the text', (tester) async {
      await _pump(tester, _composer(rtl: rtl));
      await tester.enterText(find.byType(TextField), 'س');
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(TextField));
      expect(tester.getCenter(_clip()).dy, greaterThan(field.bottom - 1));
      expect(tester.getCenter(_send()).dy, greaterThan(field.bottom - 1));
      // physical order: paperclip left, send right - in every language
      expect(tester.getCenter(_clip()).dx, lessThan(tester.getCenter(_send()).dx));
    });

    testWidgets('$tag many lines: the field stops at eight lines and the buttons stay in view', (tester) async {
      await _pump(tester, _composer(rtl: rtl));
      await tester.enterText(find.byType(TextField), List.filled(14, 'x').join('\n'));
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(TextField));
      expect(field.height, lessThanOrEqualTo(197));
      expect(tester.getCenter(_send()).dy, greaterThan(field.bottom - 1));
      expect(tester.getRect(find.byType(Gate3Composer)).bottom, lessThanOrEqualTo(700));
    });
  }

  testWidgets('the page can cap the text area (keyboard open): the field obeys, the buttons are still there',
      (tester) async {
    await _pump(tester, _composer(rtl: true, maxFieldHeight: 80));
    await tester.enterText(find.byType(TextField), List.filled(14, 'x').join('\n'));
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(TextField));
    expect(field.height, lessThanOrEqualTo(80));
    expect(_send(), findsOneWidget);
    expect(tester.getCenter(_send()).dy, greaterThan(field.bottom - 1));
  });

  testWidgets('a cap below the minimum never squeezes the field below one line', (tester) async {
    await _pump(tester, _composer(rtl: false, maxFieldHeight: 10));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextField)).height, greaterThanOrEqualTo(44));
  });

  testWidgets('emptying the box returns to the single row (mic again)', (tester) async {
    await _pump(tester, _composer(rtl: false));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();
    expect(_send(), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(_mic(), findsOneWidget);
    expect(tester.getCenter(_clip()).dy, closeTo(tester.getCenter(_mic()).dy, 1));
  });

  testWidgets('long text shows a scrollbar beside the text; short text does not', (tester) async {
    await _pump(tester, _composer(rtl: true));
    await tester.enterText(find.byType(TextField), 'سلام');
    await tester.pumpAndSettle();
    expect(find.byType(Scrollbar), findsOneWidget);
    final controller = tester.widget<TextField>(find.byType(TextField)).scrollController!;
    expect(controller.position.maxScrollExtent, 0); // nothing to scroll: the thumb stays hidden

    await tester.enterText(find.byType(TextField), List.filled(20, 'x').join('
'));
    await tester.pumpAndSettle();
    expect(controller.position.maxScrollExtent, greaterThan(0)); // longer than the box: the thumb is drawn
  });

  group('room maths (keyboard open, 409dp of height, the real numbers of the phone test)', () {
    const echoCompact = 44 + 96; // SediLivingEcho.topInset + compactCanvas
    const tray = 88.0;

    ({double maxField, bool hideEcho}) plan({required bool trayOpen, required double available}) =>
        Gate3ComposerFit.plan(
          available: available,
          trayExtra: trayOpen ? tray : 0,
          echoHeight: echoCompact.toDouble(),
          dockHeight: 0, // the resonance steps aside while the keyboard is open
          bannerHeight: 0,
        );

    // the composer needs chrome + at least one line; everything above it plus that must fit
    bool fits(double available, bool trayOpen, ({double maxField, bool hideEcho}) p) {
      final field = p.maxField < Gate3ComposerFit.minField ? Gate3ComposerFit.minField : p.maxField;
      final above = (trayOpen ? tray : 0) + (p.hideEcho ? 0 : echoCompact);
      return above + field + Gate3ComposerFit.chrome <= available;
    }

    test('tray open or closed, nothing overflows and the text area keeps real room', () {
      for (final trayOpen in [false, true]) {
        final p = plan(trayOpen: trayOpen, available: 409);
        expect(fits(409, trayOpen, p), isTrue, reason: 'trayOpen=$trayOpen');
        expect(p.hideEcho, isFalse);
      }
      // closed tray: room for the full eight lines; open tray: still about three
      expect(plan(trayOpen: false, available: 409).maxField, greaterThanOrEqualTo(150));
      expect(plan(trayOpen: true, available: 409).maxField, greaterThanOrEqualTo(80));
    });

    test('smaller screens: the header gives way instead of overflowing', () {
      for (final available in [300.0, 280.0, 260.0, 240.0]) {
        for (final trayOpen in [false, true]) {
          final p = plan(trayOpen: trayOpen, available: available);
          expect(fits(available, trayOpen, p), isTrue, reason: 'h=$available tray=$trayOpen');
        }
      }
    });

    test('a roomy screen never limits below the eight-line cap', () {
      expect(plan(trayOpen: false, available: 800).maxField, greaterThanOrEqualTo(197));
    });
  });
}
