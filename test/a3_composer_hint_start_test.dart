import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Where the letters of [finder] really are (the Text box itself spans the whole field, so its rect says nothing
/// about the alignment of the glyphs).
Rect _glyphRect(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final length = paragraph.text.toPlainText().length;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  );
  var rect = boxes.first.toRect();
  for (final box in boxes.skip(1)) {
    rect = rect.expandToInclude(box.toRect());
  }
  return rect.shift(paragraph.localToGlobal(Offset.zero));
}

double _hintOpacity(WidgetTester tester, String hint) {
  final fade = find.ancestor(
    of: find.text(hint),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(fade.first).opacity;
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
    final glyphs = _glyphRect(tester, find.text('صحبت با صدی'));
    expect(glyphs.center.dx, greaterThan(field.center.dx));
    expect(field.right - glyphs.right, lessThan(24));
  });

  testWidgets('LTR (en): placeholder sits at the left edge of the field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _composer(placeholder: 'Talk to Sedi', rtl: false)),
      ),
    );
    await tester.pump();

    final field = tester.getRect(find.byType(TextField));
    final glyphs = _glyphRect(tester, find.text('Talk to Sedi'));
    expect(glyphs.center.dx, lessThan(field.center.dx));
    expect(glyphs.left - field.left, lessThan(24));
  });

  testWidgets('placeholder fades out as soon as the user types', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _composer(placeholder: 'صحبت با صدی', rtl: true)),
      ),
    );
    await tester.pump();
    expect(_hintOpacity(tester, 'صحبت با صدی'), 1.0);

    await tester.enterText(find.byType(TextField), 'س');
    await tester.pumpAndSettle();
    expect(_hintOpacity(tester, 'صحبت با صدی'), 0.0);
  });
}
