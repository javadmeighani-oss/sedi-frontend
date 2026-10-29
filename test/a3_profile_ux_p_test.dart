import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('Profile groups user info into a white card without new editable fields',
      () {
    final src = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    );
    expect(src.contains('A3DestinationSurface.canvas'), isTrue);
    expect(src.contains('A3DestinationCard'), isTrue);
    expect(src.contains('userInformationSection'), isTrue);
    expect(src.contains('userSummarySection'), isTrue);
    expect(src.contains('AuthHelper.performLogout'), isTrue);
    expect(src.contains('_phoneCard'), isTrue);
    expect(src.contains('TextDirection.ltr'), isTrue);
    expect(src.contains('A2PhoneE164'), isTrue);
    expect(src.contains('OtpInputHelper'), isTrue); // pilot V1: one code field, same digit rules
    expect(src.contains('/auth/me/profile-summary'), isTrue);
    expect(src.contains('fetchMe'), isTrue);
    expect(src.contains('requestPhoneChangeOtp'), isTrue);
    expect(src.contains('verifyPhoneChangeOtp'), isTrue);
    expect(src.contains('canonicalProfileSummaryText'), isTrue);

    final infoIdx = src.indexOf('userInformationSection');
    final phoneCallIdx = src.indexOf('_phoneCard(l10n)');
    final summaryCallIdx = src.indexOf('_buildSummaryCard(l10n)');
    final logoutCallIdx =
        src.indexOf('AuthHelper.performLogout(context: context)');
    expect(infoIdx, greaterThan(0));
    expect(phoneCallIdx, greaterThan(infoIdx));
    expect(summaryCallIdx, greaterThan(phoneCallIdx));
    expect(logoutCallIdx, greaterThan(summaryCallIdx));
  });
}
