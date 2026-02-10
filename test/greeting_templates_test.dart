import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/logic/greeting_templates.dart';

void main() {
  group('getIntroGreeting', () {
    test('FA contains صدی (never سدی)', () {
      final text = getIntroGreeting('fa');
      expect(text, contains('صدی'));
      expect(text, isNot(contains('سدی')));
    });

    test('FA mentions گجت and مراقبت پیوسته', () {
      final text = getIntroGreeting('fa');
      expect(text, contains('گجت'));
      expect(text, contains('مراقبت پیوسته'));
    });

    test('EN contains Sedi', () {
      final text = getIntroGreeting('en');
      expect(text, contains('Sedi'));
    });

    test('EN mentions specialized gadgets and continuous', () {
      final text = getIntroGreeting('en');
      expect(text.toLowerCase(), contains('specialized gadgets'));
      expect(text.toLowerCase(), contains('continuous'));
    });

    test('AR contains صدی (never سدی)', () {
      final text = getIntroGreeting('ar');
      expect(text, contains('صدی'));
      expect(text, isNot(contains('سدی')));
    });

    test('unknown locale defaults to EN greeting', () {
      final text = getIntroGreeting('de');
      expect(text, contains('Sedi'));
    });
  });
}
