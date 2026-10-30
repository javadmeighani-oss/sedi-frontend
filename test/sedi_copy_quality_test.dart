import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/copy/sedi_copy.dart';
import 'package:sedi_app/core/notifications/local_notifications_service.dart';

/// Quality gate for the app-side copy catalog (R-043). Mirrors backend/tests/test_sedi_copy_quality.py.
void main() {
  final entries = SediCopy.entries;

  final placeholder = RegExp(r'\{([a-zA-Z_][a-zA-Z0-9_]*)\}');
  const zwnj = '‌';
  final faJoinedVerb = RegExp(
    '(?<![؀-ۿ])ن?می(?:شه|شی|شم|خوام|خوای|خواد|تونم|تونی|تونه|کنم|کنی|کنه|دم|دی|ده|گم|گی|گه|ره|رم|ری)(?![؀-ۿ])',
  );
  final faMiSpace = RegExp('(?<![؀-ۿ])ن?می (?=[؀-ۿ])');
  final faHaSpace = RegExp('[؀-ۿ] ها(?:ی|یی)?(?![؀-ۿ])');
  final doubleSpace = RegExp(r'\S {2,}\S');

  // phrases that were wrong once and must never come back
  const banned = <String, String>{
    'ارسال پسند': 'ungrammatical («در حال ارسال پسند…»)',
    'ارسال نپسند': 'ungrammatical («در حال ارسال نپسند…»)',
    'تسجيل حضور': 'means attendance registration, not a check-in',
    'پیگیری ارتباط': 'awkward label for a check-in',
    'سدی': 'the brand is «صدی»',
    'میشی': 'missing half-space',
  };

  test('every key has fa, ar and en, non-empty', () {
    expect(entries, isNotEmpty);
    entries.forEach((key, value) {
      expect(value.keys.toSet(), SediCopy.languages.toSet(), reason: key);
      for (final text in value.values) {
        expect(text.trim(), isNotEmpty, reason: key);
      }
    });
  });

  test('the same placeholders in every language', () {
    entries.forEach((key, value) {
      final sets = value.values
          .map((t) => (placeholder.allMatches(t).map((m) => m.group(1)).toList()..sort()).join(','))
          .toSet();
      expect(sets.length, 1, reason: '$key: placeholders differ between languages');
    });
  });

  test('Persian orthography', () {
    entries.forEach((key, value) {
      final fa = value['fa']!;
      expect(RegExp('[يكةى]').hasMatch(fa), isFalse, reason: '$key: Arabic letter in Persian text');
      expect(faJoinedVerb.hasMatch(fa), isFalse, reason: '$key: missing half-space after می/نمی');
      expect(faMiSpace.hasMatch(fa), isFalse, reason: '$key: می/نمی separated by a space');
      expect(faHaSpace.hasMatch(fa), isFalse, reason: '$key: plural «ها» separated by a space');
      expect(doubleSpace.hasMatch(fa), isFalse, reason: '$key: double space');
    });
  });

  test('Arabic uses Arabic letters (the brand keeps its Persian Yeh)', () {
    entries.forEach((key, value) {
      final ar = value['ar']!.replaceAll('صدی', '');
      expect(RegExp('[یک]').hasMatch(ar), isFalse, reason: key);
    });
  });

  test('banned phrases never return', () {
    entries.forEach((key, value) {
      for (final lang in value.keys) {
        banned.forEach((phrase, why) {
          expect(value[lang]!.contains(phrase), isFalse, reason: '$key[$lang] contains "$phrase": $why');
        });
      }
    });
  });

  test('tray labels come from the catalog and keep their meaning', () {
    expect(fallbackActionLabel('open_chat', 'fa'), 'صحبت با صدی');
    expect(fallbackActionLabel('open_chat', 'ar-SA'), 'التحدث مع صدی');
    expect(fallbackActionLabel('done', 'en'), 'Done');
    expect(fallbackActionLabel('unknown_action', 'fa'), 'unknown_action');
    expect(trayProcessingLabel('dislike', 'fa'), 'در حال ثبت نظرت…');
    expect(trayProcessingLabel('open_chat', 'xx'), 'Preparing…');
    expect(trayProcessingLabel('something_else', 'ar'), 'جارٍ المعالجة…');
  });

  test('catalog lookup normalises the language and never throws', () {
    expect(SediCopy.normalizeLanguage('fa-IR'), 'fa');
    expect(SediCopy.normalizeLanguage(' AR '), 'ar');
    expect(SediCopy.normalizeLanguage('fr'), 'en');
    expect(SediCopy.normalizeLanguage(null), 'en');
    expect(SediCopy.t('inbox.talkToSedi', 'fa'), 'صحبت با صدی');
    expect(SediCopy.t('no.such.key', 'fa'), 'no.such.key');
    expect(zwnj.length, 1);
  });
}
