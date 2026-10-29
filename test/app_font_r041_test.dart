import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

/// R-041 (Javad 2026-10-29): the app uses ONE bundled, licensed font for Persian, Arabic and English - Vazirmatn
/// («وزیر») - instead of whatever the phone happens to have.
void main() {
  const weights = {
    'Regular': 400,
    'Medium': 500,
    'SemiBold': 600,
    'Bold': 700,
    'ExtraBold': 800,
  };

  test('pubspec declares the Vazirmatn family with its five weights', () {
    final pubspec = _read('pubspec.yaml');
    expect(pubspec.contains('family: Vazirmatn'), isTrue);
    weights.forEach((name, weight) {
      expect(pubspec.contains('assets/fonts/Vazirmatn-$name.ttf'), isTrue, reason: name);
      expect(
        RegExp('Vazirmatn-$name\\.ttf\\s*\\r?\\n\\s*weight: $weight').hasMatch(pubspec),
        isTrue,
        reason: '$name = $weight',
      );
    });
  });

  test('the font files are real TrueType fonts and the licence is shipped with them', () {
    for (final name in weights.keys) {
      final bytes = File('assets/fonts/Vazirmatn-$name.ttf').readAsBytesSync();
      expect(bytes.length, greaterThan(50000), reason: name);
      expect(bytes.sublist(0, 4), [0, 1, 0, 0], reason: '$name is a TrueType file');
    }
    expect(_read('assets/fonts/OFL.txt').contains('SIL Open Font License'), isTrue);
  });

  test('the app theme uses it everywhere (no per-language font hacks, no default system font)', () {
    final app = _read('lib/app.dart');
    expect(app.contains("fontFamily: 'Vazirmatn'"), isTrue);
    expect(app.contains("fontFamily: 'default'"), isFalse);
  });
}
