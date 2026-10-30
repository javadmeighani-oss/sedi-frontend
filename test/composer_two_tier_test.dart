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

    testWidgets('$tag many lines: the field stops at six lines and the buttons stay in view', (tester) async {
      await _pump(tester, _composer(rtl: rtl));
      await tester.enterText(find.byType(TextField), List.filled(14, 'x').join('\n'));
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(TextField));
      expect(field.height, lessThanOrEqualTo(154));
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
}
