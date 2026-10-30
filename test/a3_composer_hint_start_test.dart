import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_composer.dart';

Gate3Composer _composer({required String placeholder, required bool rtl}) {
  return Gate3Composer(
    placeholder: placeholder,
    lang: rtl ? 'fa' : 'en',
    isRtl: rtl,
    isRecording: false,
    recordingTime: '00:00',
    onListeningChanged: (_) {},
    onSendText: (_) {},
    onStartRecording: () {},
    onStopRecordingAndSend: () {},
  );
}

/// The "Talk to Sedi" placeholder must sit where typing starts and vanish when typing starts.
/// Regression: the button row is forced LTR (paperclip left), which pulled the placeholder to the left in fa/ar.
void main() {
  testWidgets('RTL (fa/ar): placeholder sits at the right edge of the field, like the typed text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _composer(placeholder: 'صحبت با صدی', rtl: true)),
      ),
    );
    await tester.pump();

    final field = tester.getRect(find.byType(TextField));
    final hint = tester.getRect(find.text('صحبت با صدی'));
    expect(hint.center.dx, greaterThan(field.center.dx));
    expect(field.right - hint.right, lessThan(24));
  });

  testWidgets('LTR (en): placeholder sits at the left edge of the field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _composer(placeholder: 'Talk to Sedi', rtl: false)),
      ),
    );
    await tester.pump();

    final field = tester.getRect(find.byType(TextField));
    final hint = tester.getRect(find.text('Talk to Sedi'));
    expect(hint.center.dx, lessThan(field.center.dx));
    expect(hint.left - field.left, lessThan(24));
  });

  testWidgets('placeholder disappears as soon as the user types', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _composer(placeholder: 'صحبت با صدی', rtl: true)),
      ),
    );
    await tester.pump();
    expect(find.text('صحبت با صدی'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'س');
    await tester.pump();
    expect(find.text('صحبت با صدی'), findsNothing);
  });
}
