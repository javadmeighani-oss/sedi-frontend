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
    expect(field.decoration?.hintStyle?.fontSize, 12.8);
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
    expect(textBox.constraints.maxHeight, 168);

    final add = tester.widget<Gate3ComposerActionButton>(
      find.widgetWithIcon(Gate3ComposerActionButton, Icons.add_rounded),
    );
    final mic = tester.widget<Gate3ComposerActionButton>(
      find.widgetWithIcon(Gate3ComposerActionButton, Icons.mic_rounded),
    );
    expect(add.size, 44);
    expect(add.iconSize, 22);
    expect(mic.size, 44);
    expect(mic.iconSize, 24);

    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(Gate3Composer),
        matching: find.byType(Row),
      ).first,
    );
    expect(row.crossAxisAlignment, CrossAxisAlignment.end);
    expect(find.byType(TextField), findsOneWidget);
  });
}
