import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

/// Pilot V1 screen 2 (R-034 / R-035, Javad 2026-10-29): the Profile is one glass screen, icons before words.
void main() {
  final page = _read('lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart');

  test('the Sedi sphere sits on the start side of the title (R-035): it comes first in the title row', () {
    final orb = page.indexOf('const SediHologramOrb(');
    final title = page.indexOf('l10n.profileTitle');
    expect(orb, greaterThan(0));
    expect(title, greaterThan(orb));
    expect(page.contains('keyedLogo: false'), isTrue);
  });

  test('the name stands alone: no avatar or icon beside it', () {
    expect(page.contains('CircleAvatar'), isFalse);
    final name = page.indexOf('_me?.name');
    final tiles = page.indexOf('_factTile(', name);
    final between = page.substring(name, tiles);
    expect(between.contains('Icon('), isFalse);
  });

  test('birthday, sex and language are icon tiles', () {
    expect(page.contains('Icons.cake_outlined'), isTrue);
    expect(page.contains('Icons.male_rounded'), isTrue);
    expect(page.contains('Icons.language_rounded'), isTrue);
    expect(page.contains('Widget _factTile('), isTrue);
  });

  test('phone: the pencil sits beside the number, the number box turns into the field in place', () {
    expect(page.contains('Icons.edit_outlined'), isTrue);
    expect(page.contains('Widget _phoneEditBox('), isTrue);
    expect(page.contains('autofocus: true'), isTrue);
    expect(page.contains('_phoneChangeWidgets'), isFalse); // the old panel is gone
  });

  test('the code box opens UNDER the number and closes on verify or cancel', () {
    final sentRow = page.indexOf('_phoneRow(l10n, number: _pendingNewPhone');
    final codeBox = page.indexOf('_codeBox(l10n)', sentRow);
    expect(sentRow, greaterThan(0));
    expect(codeBox, greaterThan(sentRow));
    expect(page.contains('Gate2OtpInput('), isTrue);
    expect(page.contains('void _cancelPhoneChange()'), isTrue);
    // verify success resets the flow (the box closes)
    expect(page.contains('_changingPhone = false;'), isTrue);
  });

  test('the OTP flow itself is untouched', () {
    expect(page.contains('requestPhoneChangeOtp'), isTrue);
    expect(page.contains('verifyPhoneChangeOtp'), isTrue);
  });

  test('icons outnumber words on the page', () {
    final icons = RegExp(r'Icons\.[a-z_0-9]+').allMatches(page).length;
    expect(icons, greaterThanOrEqualTo(12));
  });

  test('memory switch is a glass row with a shield icon and keeps its Switch', () {
    final c = _read('lib/features/gate3_interactive/presentation/widgets/gate3_profile_memory_control.dart');
    expect(c.contains('Icons.verified_user_outlined'), isTrue);
    expect(c.contains('Switch('), isTrue);
    expect(c.contains('SediGlass.card'), isTrue);
  });
}
