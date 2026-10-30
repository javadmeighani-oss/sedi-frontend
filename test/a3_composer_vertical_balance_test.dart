import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_composer.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_composer_action_button.dart';

Gate3Composer _composer({required String placeholder}) {
  return Gate3Composer(
    placeholder: placeholder,
    lang: 'en',
    isRtl: false,
    isRecording: false,
    recordingTime: '00:00',
    onListeningChanged: (_) {},
    onSendText: (_) {},
    onStartRecording: () {},
    onStopRecordingAndSend: () {},
  );
}

void main() {
  testWidgets(
      'hologram composer is a single glass row [+] [field] [mic] without a fixed height',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _composer(placeholder: 'Talk to Sedi'),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontSize, 16.2);
    expect(field.decoration?.hintStyle?.fontSize, 16.2); // the placeholder is as big as the typed text
    expect(field.style?.fontSize, field.decoration?.hintStyle?.fontSize);
    expect(field.textAlignVertical, TextAlignVertical.center);
    expect(field.minLines, 1);
    expect(field.maxLines, isNull);

    final textBox = tester.widget<ConstrainedBox>(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(ConstrainedBox),
      ).first,
    );
    expect(textBox.constraints.minHeight, 44);
    expect(textBox.constraints.maxHeight, 197); // eight lines, then the text scrolls (with a scrollbar)

    final add = tester.widget<Gate3ComposerActionButton>(
      find.widgetWithIcon(Gate3ComposerActionButton, Icons.attach_file_rounded),
    );
    final mic = tester.widget<Gate3ComposerActionButton>(
      find.widgetWithIcon(Gate3ComposerActionButton, Icons.mic_rounded),
    );
    // pilot V1 (R-034): a bare 48dp paperclip and a 52dp pistachio 3D mic
    expect(add.size, 48);
    expect(add.iconSize, 28);
    expect(add.bare, isTrue);
    expect(mic.size, 52);
    expect(mic.iconSize, 24);
    expect(mic.sphere, isTrue);

    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(Gate3Composer),
        matching: find.byType(Row),
      ).first,
    );
    // the empty box: the placeholder is level with the paperclip and the mic
    expect(row.crossAxisAlignment, CrossAxisAlignment.center);
    expect(find.byType(TextField), findsOneWidget);
  });
}
