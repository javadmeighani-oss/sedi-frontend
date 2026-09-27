import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/auth_otp/presentation/gate2_otp_input.dart';

void main() {
  TextEditingValue apply({
    required String oldText,
    required String newText,
    required TextSelection oldSel,
  }) {
    return OtpInputHelper.applyEdit(
      oldValue: TextEditingValue(text: oldText, selection: oldSel),
      newValue: TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  Future<void> pumpOtp(
    WidgetTester tester, {
    required TextEditingController controller,
    required FocusNode focusNode,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate2OtpInput(
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('full OTP paste/autofill replaces entire code', () {
    test('1. empty + paste 654321 → 654321', () {
      final v = apply(
        oldText: '',
        newText: '654321',
        oldSel: const TextSelection.collapsed(offset: 0),
      );
      expect(v.text, '654321');
    });

    test('2. partial 12 + paste 654321 → 654321', () {
      final v = apply(
        oldText: '12',
        newText: '12654321',
        oldSel: const TextSelection.collapsed(offset: 2),
      );
      expect(v.text, '654321');
    });

    test('3. full 123456 + selected middle + paste 654321 → 654321', () {
      final v = apply(
        oldText: '123456',
        newText: '12654321456',
        oldSel: const TextSelection(baseOffset: 2, extentOffset: 3),
      );
      expect(v.text, '654321');
      expect(v.text.contains('126543'), isFalse);
    });

    test('7. Persian/Arabic paste normalization preserved', () {
      expect(
        apply(
          oldText: '',
          newText: '۶۵۴۳۲۱',
          oldSel: const TextSelection.collapsed(offset: 0),
        ).text,
        '654321',
      );
      expect(
        apply(
          oldText: '123456',
          newText: '٦٥٤٣٢١',
          oldSel: const TextSelection(baseOffset: 2, extentOffset: 3),
        ).text,
        '654321',
      );
    });
  });

  group('manual slot edit', () {
    test('4. tap slot 2 + type 9: 123456 → 129456', () {
      final v = apply(
        oldText: '123456',
        newText: '129456',
        oldSel: const TextSelection(baseOffset: 2, extentOffset: 3),
      );
      expect(v.text, '129456');
    });

    test('5. tapping slot never truncates code', () {
      const code = '123456';
      for (var i = 0; i < OtpInputHelper.codeLength; i++) {
        final sel = OtpInputHelper.selectionForSlot(code, i);
        expect(OtpInputHelper.sanitize(code), '123456');
        expect(sel.start, i);
        expect(sel.end, i + 1);
      }
    });

    test('6. backspace/edit remains deterministic', () {
      final selected = apply(
        oldText: '123456',
        newText: '12456',
        oldSel: const TextSelection(baseOffset: 2, extentOffset: 3),
      );
      expect(selected.text, '12456');
      expect(selected.selection.extentOffset, 2);

      final atEnd = apply(
        oldText: '123',
        newText: '12',
        oldSel: const TextSelection.collapsed(offset: 3),
      );
      expect(atEnd.text, '12');
      expect(atEnd.selection.extentOffset, 2);
    });
  });

  group('caret only for active edit', () {
    testWidgets('8. paste/autofill does not leave caret over filled digits',
        (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpOtp(tester, controller: controller, focusNode: focusNode);
      await tester.enterText(find.byType(TextField), '654321');
      await tester.pump();

      expect(controller.text, '654321');
      expect(find.byType(OtpSlotCaret), findsNothing);
    });

    testWidgets('8. empty active slot shows centered caret', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpOtp(tester, controller: controller, focusNode: focusNode);
      await tester.tap(find.byType(Gate2OtpInput));
      await tester.pump();

      final caret = tester.widget<OtpSlotCaret>(find.byType(OtpSlotCaret));
      expect(caret.placement, OtpCaretPlacement.emptyCenter);
      expect(OtpSlotCaret.thickness, 1);
    });

    testWidgets('8. tapped filled slot shows thin beside caret, no overlap',
        (tester) async {
      final controller = TextEditingController(text: '123456');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpOtp(tester, controller: controller, focusNode: focusNode);
      expect(find.byType(OtpSlotCaret), findsNothing);

      await tester.tap(find.byKey(const ValueKey('a2-otp-slot-2')));
      await tester.pump();

      expect(controller.text, '123456');
      final caret = tester.widget<OtpSlotCaret>(find.byType(OtpSlotCaret));
      expect(caret.placement, OtpCaretPlacement.filledBeside);
      expect(caret.placement, isNot(OtpCaretPlacement.emptyCenter));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      final digitBox = tester.getRect(find.text('3'));
      final caretBox = tester.getRect(find.byType(OtpSlotCaret));
      expect(caretBox.width, 1);
      expect(caretBox.left, greaterThanOrEqualTo(digitBox.right));
    });
  });

  group('OTP slot tap keyboard', () {
    testWidgets('tap empty slot focuses numeric field and shows keyboard',
        (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpOtp(tester, controller: controller, focusNode: focusNode);
      expect(focusNode.hasFocus, isFalse);

      final fieldBefore = tester.widget<TextField>(find.byType(TextField));
      expect(fieldBefore.autofocus, isFalse);
      expect(fieldBefore.keyboardType, TextInputType.number);
      expect(fieldBefore.controller, same(controller));
      expect(fieldBefore.focusNode, same(focusNode));
      expect(find.byType(TextField), findsOneWidget);
      for (var i = 0; i < OtpInputHelper.codeLength; i++) {
        expect(find.byKey(ValueKey('a2-otp-slot-$i')), findsOneWidget);
      }

      tester.testTextInput.log.clear();
      await tester.tap(find.byKey(const ValueKey('a2-otp-slot-0')));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, isEmpty);
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.extentOffset, 0);
      expect(
        tester.testTextInput.log.map((call) => call.method),
        contains('TextInput.show'),
      );
    });

    testWidgets('tap filled slot keeps the full code and selects that slot',
        (tester) async {
      final controller = TextEditingController(text: '123456');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpOtp(tester, controller: controller, focusNode: focusNode);
      tester.testTextInput.log.clear();
      await tester.tap(find.byKey(const ValueKey('a2-otp-slot-3')));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, '123456');
      expect(controller.selection.start, 3);
      expect(controller.selection.end, 4);
      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.number,
      );
      expect(
        tester.testTextInput.log.map((call) => call.method),
        contains('TextInput.show'),
      );
    });

    testWidgets('tap while focus remains reopens the keyboard', (tester) async {
      final controller = TextEditingController(text: '123456');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpOtp(tester, controller: controller, focusNode: focusNode);
      await tester.tap(find.byKey(const ValueKey('a2-otp-slot-4')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // Android Back hides the IME and leaves the focus node focused.
      tester.testTextInput.hide();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isFalse);

      tester.testTextInput.log.clear();
      await tester.tap(find.byKey(const ValueKey('a2-otp-slot-1')));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, '123456');
      expect(controller.selection.start, 1);
      expect(controller.selection.end, 2);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        tester.testTextInput.log.map((call) => call.method),
        contains('TextInput.show'),
      );
    });
  });
}
