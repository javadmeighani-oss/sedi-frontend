import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Production diagnostics 2026-11-07: «not now» reached the backend but the reason answers of the grown notification almost never
/// did (7 dislikes, 1 reason in 7 days). The headless engine that delivers a tray answer must register Dart plugins first, or the
/// session token (SharedPreferences migration) and the pending-action store cannot be read and the answer is dropped silently.
void main() {
  test('the headless tray entry registers Dart plugins before touching storage or the network', () {
    final src = File('lib/core/notifications/sedi_tray_native.dart').readAsStringSync();
    expect(src, contains("import 'dart:ui' show DartPluginRegistrant, PluginUtilities;"));
    final entry = src.indexOf('Future<void> sediTrayBackgroundEntry()');
    final reg = src.indexOf('DartPluginRegistrant.ensureInitialized();', entry);
    final use = src.indexOf('deliverReasonAnswer(', entry);
    expect(entry, greaterThan(0));
    expect(reg, greaterThan(entry));
    expect(reg, lessThan(use));
  });
}
