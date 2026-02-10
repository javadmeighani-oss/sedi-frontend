import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/health/logic/vitals_cache.dart';
import 'package:sedi_app/features/health/logic/vitals_history.dart';

void main() {
  CachedVitals entry(double? hr, DateTime? createdAt) => CachedVitals(
        heartRate: hr,
        createdAt: createdAt,
      );

  group('mergeAndTrim', () {
    test('append then cap to 50 items', () {
      final now = DateTime.now();
      final current = List.generate(50, (i) => entry(60.0 + i, now.subtract(Duration(minutes: i))));
      final newEntry = entry(99.0, now.add(const Duration(seconds: 1)));
      final result = mergeAndTrim(current, newEntry);
      expect(result.length, 50);
      expect(result.first.heartRate, 99.0);
    });

    test('dedup by created_at + heart_rate keeps one', () {
      final t = DateTime.utc(2025, 2, 10, 12, 0);
      final current = [entry(72.0, t)];
      final newEntry = entry(72.0, t);
      final result = mergeAndTrim(current, newEntry);
      expect(result.length, 1);
      expect(result.first.heartRate, 72.0);
    });

    test('dedup by created_at only when heart_rate missing', () {
      final t = DateTime.utc(2025, 2, 10, 12, 0);
      final current = [CachedVitals(createdAt: t)];
      final newEntry = CachedVitals(createdAt: t);
      final result = mergeAndTrim(current, newEntry);
      expect(result.length, 1);
    });

    test('same created_at different heart_rate keeps both', () {
      final t = DateTime.utc(2025, 2, 10, 12, 0);
      final current = [entry(70.0, t)];
      final newEntry = entry(80.0, t);
      final result = mergeAndTrim(current, newEntry);
      expect(result.length, 2);
    });

    test('minute bucket: same minute different seconds dedupes (open page twice)', () {
      final t1 = DateTime.utc(2025, 2, 10, 12, 0, 0);
      final t2 = DateTime.utc(2025, 2, 10, 12, 0, 30);
      final current = [entry(72.0, t1)];
      final newEntry = entry(72.0, t2);
      final result = mergeAndTrim(current, newEntry);
      expect(result.length, 1);
    });
  });

  group('purgeOlderThan7Days', () {
    test('removes entries older than 7 days', () {
      final now = DateTime.now();
      final old = entry(70.0, now.subtract(const Duration(days: 8)));
      final recent = entry(72.0, now.subtract(const Duration(days: 3)));
      final list = [old, recent];
      final result = purgeOlderThan7Days(list);
      expect(result.length, 1);
      expect(result.first.heartRate, 72.0);
    });

    test('keeps entries within 7 days', () {
      final now = DateTime.now();
      final e = entry(72.0, now.subtract(const Duration(days: 6)));
      final result = purgeOlderThan7Days([e]);
      expect(result.length, 1);
    });
  });

  group('computeStats', () {
    test('avg computation rounding', () {
      final list = [
        entry(70.0, DateTime.now()),
        entry(72.0, DateTime.now()),
        entry(75.0, DateTime.now()),
      ];
      final stats = computeStats(list);
      expect(stats.avgHeartRate7d, 72); // (70+72+75)/3 = 72.33 -> 72
      expect(stats.countRecords7d, 3);
      expect(stats.minHeartRate7d, 70);
      expect(stats.maxHeartRate7d, 75);
    });

    test('rounds up correctly', () {
      final list = [entry(72.0, DateTime.now()), entry(73.0, DateTime.now())];
      final stats = computeStats(list);
      expect(stats.avgHeartRate7d, 73); // 72.5 -> 73
    });

    test('no HR data returns null avg and count only', () {
      final list = [CachedVitals(createdAt: DateTime.now())];
      final stats = computeStats(list);
      expect(stats.avgHeartRate7d, isNull);
      expect(stats.minHeartRate7d, isNull);
      expect(stats.maxHeartRate7d, isNull);
      expect(stats.countRecords7d, 1);
    });

    test('empty list returns zero count', () {
      final stats = computeStats([]);
      expect(stats.countRecords7d, 0);
      expect(stats.avgHeartRate7d, isNull);
    });
  });
}
