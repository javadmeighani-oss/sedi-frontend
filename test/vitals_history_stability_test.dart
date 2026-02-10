import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/health/logic/vitals_cache.dart';
import 'package:sedi_app/features/health/logic/vitals_history.dart';

void main() {
  group('History stability', () {
    test('repeated append of same entry does not increase list', () {
      final entry = CachedVitals(
        heartRate: 72.0,
        createdAt: DateTime.utc(2025, 2, 10, 12, 0),
      );
      List<CachedVitals> list = [];
      for (int i = 0; i < 5; i++) {
        list = mergeAndTrim(list, entry);
      }
      expect(list.length, 1);
      expect(list.first.heartRate, 72.0);
    });

    test('same entry merged into existing list does not grow', () {
      final t = DateTime.utc(2025, 2, 10, 12, 0);
      final entry = CachedVitals(heartRate: 72.0, createdAt: t);
      List<CachedVitals> list = [entry];
      expect(list.length, 1);
      list = mergeAndTrim(list, entry);
      expect(list.length, 1);
      list = mergeAndTrim(list, entry);
      expect(list.length, 1);
    });
  });
}
