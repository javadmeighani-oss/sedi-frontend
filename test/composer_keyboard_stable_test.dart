import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Javad 2026-10-28: the keyboard closed and re-opened while typing in the chat box. Cause: once the text wrapped, the
/// composer switched from a Row to a Column and the TextField (no key) was rebuilt in a new place, dropping the input
/// connection. The field must keep its element across both layouts.
void main() {
  test('the composer field keeps one GlobalKey across the row and the wide layout', () {
    final src = File('lib/features/gate3_interactive/presentation/widgets/gate3_composer.dart').readAsStringSync();
    expect(src.contains("final GlobalKey _fieldKey = GlobalKey("), isTrue);
    expect(src.contains('key: _fieldKey'), isTrue);
    // both layouts place the very same keyed field widget
    expect(RegExp(r'child:\s*field,').allMatches(src).length, 2);
    // the text field itself is never created per layout
    expect('_buildTextField('.allMatches(src).length, 2); // definition + the single call inside the keyed field
  });
}
