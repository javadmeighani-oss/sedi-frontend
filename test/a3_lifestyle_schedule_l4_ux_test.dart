import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('L4 Schedule uses structured event cards and locked reminder presets', () {
    final src = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart',
    );
    expect(src.contains('A3DestinationSurface.canvas'), isTrue);
    expect(src.contains('gate3PaleOliveBackground'), isFalse);
    expect(src.contains('A3DestinationCard'), isTrue);
    // R-031: today first, then what is coming up (grouping lives in the pure domain file).
    final domain = _read('lib/features/lifestyle/domain/schedule_today.dart');
    expect(src.contains('buildToday'), isTrue);
    expect(src.contains('buildUpcoming'), isTrue);
    expect(domain.contains('buildToday'), isTrue);
    expect(src.contains('patchReminder'), isTrue);
    final sheets = _read(
      'lib/features/lifestyle/presentation/widgets/schedule_reminder_sheets.dart',
    );
    expect(sheets.contains('1440'), isTrue);
    expect(sheets.contains('60'), isTrue);
    expect(src.contains('join(\' · \')'), isFalse);
    expect(src.contains('LifestyleScheduleService'), isTrue);
    expect(src.contains('listI8Actions'), isFalse); // D-130: the unclear governed-actions block is gone
    expect(src.contains('.location'), isTrue);
    expect(domain.contains('e.eventType'), isTrue);
    expect(domain.contains('e.title'), isTrue);
  });
}
