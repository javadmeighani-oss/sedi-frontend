import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/theme/sedi_fonts.dart';

String _read(String path) => File(path).readAsStringSync();

/// R-041 (Javad 2026-10-29): the app uses licensed fonts BUNDLED with it, one per language, never the phone's own font:
/// Persian = Vazirmatn («وزیر»), Arabic = IBM Plex Sans Arabic, English = IBM Plex Sans (all SIL Open Font Licence).
void main() {
  const families = <String, List<String>>{
    'Vazirmatn': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    'IBMPlexSans': ['Regular', 'Medium', 'SemiBold', 'Bold'],
    'IBMPlexSansArabic': ['Regular', 'Medium', 'SemiBold', 'Bold'],
  };
  const weight = {'Regular': 400, 'Medium': 500, 'SemiBold': 600, 'Bold': 700, 'ExtraBold': 800};

  test('pubspec declares the three families with their weights', () {
    final pubspec = _read('pubspec.yaml');
    families.forEach((family, names) {
      expect(pubspec.contains('family: $family'), isTrue, reason: family);
      for (final name in names) {
        expect(
          RegExp('$family-$name\\.ttf\\s*\\r?\\n\\s*weight: ${weight[name]}').hasMatch(pubspec),
          isTrue,
          reason: '$family $name = ${weight[name]}',
        );
      }
    });
  });

  test('every font file is a real TrueType font and every family ships its licence', () {
    families.forEach((family, names) {
      for (final name in names) {
        final bytes = File('assets/fonts/$family-$name.ttf').readAsBytesSync();
        expect(bytes.length, greaterThan(50000), reason: '$family $name');
        expect(bytes.sublist(0, 4), [0, 1, 0, 0], reason: '$family $name is TrueType');
      }
      expect(_read('assets/fonts/OFL-$family.txt').contains('SIL Open Font License'), isTrue, reason: family);
    });
  });

  test('each language gets its own licensed family, the others serve as fallback', () {
    expect(SediFonts.familyFor('fa'), 'Vazirmatn');
    expect(SediFonts.familyFor('ar'), 'IBMPlexSansArabic');
    expect(SediFonts.familyFor('en'), 'IBMPlexSans');
    expect(SediFonts.familyFor('anything-else'), 'IBMPlexSans');
    for (final lang in ['fa', 'ar', 'en']) {
      final fallback = SediFonts.fallbackFor(lang);
      expect(fallback.length, 2);
      expect(fallback.contains(SediFonts.familyFor(lang)), isFalse);
      for (final f in fallback) {
        expect(families.containsKey(f), isTrue);
      }
    }
  });

  test('the app theme follows the language and never uses the system font', () {
    final app = _read('lib/app.dart');
    expect(app.contains('SediFonts.familyFor(_locale.languageCode)'), isTrue);
    expect(app.contains('SediFonts.fallbackFor(_locale.languageCode)'), isTrue);
    expect(app.contains("fontFamily: 'default'"), isFalse);
    expect(app.contains("fontFamily: 'Vazirmatn'"), isFalse);
  });
}
