import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_phone_e164.dart';

void main() {
  group('A2PhoneE164', () {
    final ir = A2PhoneE164.byIso2('IR');
    final us = A2PhoneE164.byIso2('US');

    test('Iranian 09xxxxxxxxx → +98…', () {
      expect(
        A2PhoneE164.normalize(nationalInput: '09121234567', dialCode: ir),
        '+989121234567',
      );
      expect(
        A2PhoneE164.isValid(nationalInput: '09121234567', dialCode: ir),
        isTrue,
      );
    });

    test('Iranian 9xxxxxxxxx without leading 0', () {
      expect(
        A2PhoneE164.normalize(nationalInput: '9121234567', dialCode: ir),
        '+989121234567',
      );
    });

    test('non-Iran dial-code case (US)', () {
      expect(
        A2PhoneE164.normalize(nationalInput: '2025551234', dialCode: us),
        '+12025551234',
      );
      expect(
        A2PhoneE164.isValid(nationalInput: '2025551234', dialCode: us),
        isTrue,
      );
    });

    test('already-E.164 input preserved (canonicalized)', () {
      expect(
        A2PhoneE164.normalize(nationalInput: '+989121234567', dialCode: ir),
        '+989121234567',
      );
      expect(
        A2PhoneE164.normalize(nationalInput: '+1 202 555 1234', dialCode: us),
        '+12025551234',
      );
    });

    test('strips spaces and hyphens', () {
      expect(
        A2PhoneE164.normalize(
          nationalInput: '0912-123-4567',
          dialCode: ir,
        ),
        '+989121234567',
      );
      expect(
        A2PhoneE164.normalize(
          nationalInput: '202 555 1234',
          dialCode: us,
        ),
        '+12025551234',
      );
    });

    test('invalid / empty phone', () {
      expect(
        A2PhoneE164.normalize(nationalInput: '', dialCode: ir),
        '',
      );
      expect(
        A2PhoneE164.isValid(nationalInput: '', dialCode: ir),
        isFalse,
      );
      expect(
        A2PhoneE164.isValid(nationalInput: '123', dialCode: ir),
        isFalse,
      );
    });

    test('never duplicates + or keeps trunk zero after dial', () {
      expect(
        A2PhoneE164.normalize(nationalInput: '+9809121234567', dialCode: ir),
        '+989121234567',
      );
      expect(
        A2PhoneE164.normalize(nationalInput: '0 9121234567', dialCode: ir),
        '+989121234567',
      );
    });

    test('country code is independent of UI language (model-level)', () {
      // Dial selection is explicit; language does not appear in normalize API.
      expect(
        A2PhoneE164.normalize(nationalInput: '2025551234', dialCode: us),
        isNot(startsWith('+98')),
      );
    });

    test('A2 phone field isolates digits and +98 as LTR; E.164 unchanged', () {
      final widgets = File(
        'lib/features/auth_otp/presentation/gate2_widgets.dart',
      ).readAsStringSync();
      final phoneStart = widgets.indexOf('static Widget phoneField');
      final phoneEnd = widgets.indexOf('static InputDecoration _inputDecoration');
      expect(phoneStart, greaterThan(0));
      expect(phoneEnd, greaterThan(phoneStart));
      final phoneField = widgets.substring(phoneStart, phoneEnd);
      expect(phoneField.contains('Directionality('), isTrue);
      expect(phoneField.contains('textDirection: TextDirection.ltr'), isTrue);
      expect(phoneField.contains('prefixIcon:'), isTrue);
      expect(phoneField.contains('prefix:'), isFalse);
      expect(phoneField.contains('prefixIcon: null'), isFalse);
      expect(phoneField.contains('CrossAxisAlignment.center'), isTrue);
      expect(phoneField.contains('Icons.phone_outlined'), isTrue);
      expect(phoneField.contains('start: 18'), isTrue);
      expect(phoneField.contains('prefixIconConstraints:'), isTrue);

      final e164 = File(
        'lib/features/auth_otp/presentation/a2_phone_e164.dart',
      ).readAsStringSync();
      expect(e164.contains("'+98'"), isTrue);
      expect(e164.contains(r'^\+98\d{10}$'), isTrue);
    });
  });
}
