import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/logic/greeting_templates.dart';

void main() {
  group('getIntroGreeting', () {
    test('FA contains صدی (never سدی)', () {
      final text = getIntroGreeting('fa');
      expect(text, contains('صدی'));
      expect(text, isNot(contains('سدی')));
    });

    test('FA states the identity: memory tiers, adviser, vital signs with the gadgets (R-048)', () {
      final text = getIntroGreeting('fa');
      expect(text, contains('گجت'));
      expect(text, contains('حافظه'));
      expect(text, contains('کوتاه‌مدت'));
      expect(text, contains('بلندمدت'));
      expect(text, contains('علائم حیاتی'));
      expect(text, contains('مشاور'));
    });

    test('EN contains Sedi', () {
      final text = getIntroGreeting('en');
      expect(text, contains('Sedi'));
    });

    test('EN states the identity: memory tiers, adviser, vital signs with the gadgets (R-048)', () {
      final text = getIntroGreeting('en');
      expect(text.toLowerCase(), contains('short, medium and long term'));
      expect(text.toLowerCase(), contains('vital signs'));
      expect(text.toLowerCase(), contains('adviser'));
      expect(text.toLowerCase(), contains('gadgets'));
    });

    test('AR states the identity with the Arabic spelling صدي (R-048, never سدی)', () {
      final text = getIntroGreeting('ar');
      expect(text, contains('صدي'));
      expect(text, isNot(contains('صدی')));
      expect(text, contains('علاماتك الحيوية'));
      expect(text, isNot(contains('سدی')));
    });

    test('unknown locale defaults to EN greeting', () {
      final text = getIntroGreeting('de');
      expect(text, contains('Sedi'));
    });
  });
}
