import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/utils/brand_name.dart';

void main() {
  // Wrong spelling that must never appear in FA/AR brand
  const String wrongBrandFa = 'سدی';

  group('sediBrandName', () {
    test('fa returns صدی (never سدی)', () {
      expect(sediBrandName('fa'), 'صدی');
      expect(sediBrandName('FA'), 'صدی');
      expect(sediBrandName('fa'), isNot(wrongBrandFa));
    });

    test('ar returns صدي (Arabic spelling, R-048; never سدی)', () {
      expect(sediBrandName('ar'), 'صدي');
      expect(sediBrandName('AR'), 'صدي');
      expect(sediBrandName('ar'), isNot(wrongBrandFa));
    });

    test('en returns Sedi', () {
      expect(sediBrandName('en'), 'Sedi');
      expect(sediBrandName('EN'), 'Sedi');
    });

    test('unknown locale defaults to Sedi', () {
      expect(sediBrandName('de'), 'Sedi');
      expect(sediBrandName('fr'), 'Sedi');
      expect(sediBrandName(''), 'Sedi');
    });
  });
}
