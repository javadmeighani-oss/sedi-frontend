import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/health/logic/vitals_cache.dart';

void main() {
  group('CachedVitals serialization', () {
    test('toJson includes all fields when set', () {
      final v = CachedVitals(
        heartRate: 72.0,
        temperature: 36.6,
        spo2: 98.0,
        createdAt: DateTime.utc(2025, 2, 9, 12, 0),
      );
      final j = v.toJson();
      expect(j['heart_rate'], 72.0);
      expect(j['temperature'], 36.6);
      expect(j['spo2'], 98.0);
      expect(j['created_at'], '2025-02-09T12:00:00.000Z');
    });

    test('toJson omits null fields', () {
      final v = const CachedVitals(heartRate: 80.0);
      final j = v.toJson();
      expect(j['heart_rate'], 80.0);
      expect(j.containsKey('temperature'), isFalse);
      expect(j.containsKey('spo2'), isFalse);
      expect(j.containsKey('created_at'), isFalse);
    });

    test('fromJson parses full object', () {
      final j = {
        'heart_rate': 75.0,
        'temperature': 36.8,
        'spo2': 97.0,
        'created_at': '2025-02-09T14:30:00.000Z',
      };
      final v = CachedVitals.fromJson(j);
      expect(v, isNotNull);
      expect(v!.heartRate, 75.0);
      expect(v.temperature, 36.8);
      expect(v.spo2, 97.0);
      expect(v.createdAt, isNotNull);
      expect(v.createdAt!.toUtc().year, 2025);
    });

    test('fromJson returns null for null or empty map', () {
      expect(CachedVitals.fromJson(null), isNull);
      expect(CachedVitals.fromJson({}), isNull);
    });

    test('round-trip: toJson then fromJson preserves data', () {
      final v = CachedVitals(
        heartRate: 72.0,
        spo2: 99.0,
        createdAt: DateTime.utc(2025, 1, 1, 0, 0),
      );
      final j = v.toJson();
      final v2 = CachedVitals.fromJson(Map<String, dynamic>.from(j));
      expect(v2, isNotNull);
      expect(v2!.heartRate, v.heartRate);
      expect(v2.spo2, v.spo2);
      expect(v2.createdAt, isNotNull);
      expect(v2.createdAt!.toUtc(), v.createdAt!.toUtc());
    });
  });

  group('Validation helpers', () {
    test('validateHeartRate accepts 30-220', () {
      expect(validateHeartRate(30), isNull);
      expect(validateHeartRate(220), isNull);
      expect(validateHeartRate(72), isNull);
    });
    test('validateHeartRate rejects out of range', () {
      expect(validateHeartRate(29), isNotNull);
      expect(validateHeartRate(221), isNotNull);
    });
    test('validateHeartRate accepts null', () {
      expect(validateHeartRate(null), isNull);
    });

    test('validateSpO2 accepts 50-100', () {
      expect(validateSpO2(50), isNull);
      expect(validateSpO2(100), isNull);
      expect(validateSpO2(98), isNull);
    });
    test('validateSpO2 rejects out of range', () {
      expect(validateSpO2(49), isNotNull);
      expect(validateSpO2(101), isNotNull);
    });

    test('validateTemperature accepts 30-45', () {
      expect(validateTemperature(30.0), isNull);
      expect(validateTemperature(45.0), isNull);
      expect(validateTemperature(36.6), isNull);
    });
    test('validateTemperature rejects out of range', () {
      expect(validateTemperature(29.9), isNotNull);
      expect(validateTemperature(45.1), isNotNull);
    });
  });
}
