import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/data/dto/health_data_create.dart';
import 'package:sedi_app/data/dto/health_data_response.dart';

void main() {
  group('HealthDataCreate', () {
    test('toJson includes user_id and optional vitals', () {
      final req = HealthDataCreate(
        userId: 1,
        heartRate: 72.0,
        temperature: 36.6,
        spo2: 98.0,
      );
      final j = req.toJson();
      expect(j['user_id'], 1);
      expect(j['heart_rate'], 72.0);
      expect(j['temperature'], 36.6);
      expect(j['spo2'], 98.0);
    });

    test('toJson omits null optional fields', () {
      final req = HealthDataCreate(userId: 2);
      final j = req.toJson();
      expect(j['user_id'], 2);
      expect(j.containsKey('heart_rate'), isFalse);
      expect(j.containsKey('temperature'), isFalse);
      expect(j.containsKey('spo2'), isFalse);
    });
  });

  group('HealthDataResponse.fromJson', () {
    test('parses backend success payload: health_id, user_id, notification_id, message', () {
      final json = {
        'user_id': 1,
        'health_id': 42,
        'notification_id': 10,
        'message': 'Health data saved.',
      };
      final r = HealthDataResponse.fromJson(json);
      expect(r.id, 42);
      expect(r.userId, 1);
      expect(r.notificationId, 10);
      expect(r.message, 'Health data saved.');
    });

    test('parses full schema: id, user_id, heart_rate, temperature, spo2, created_at', () {
      final json = {
        'id': 5,
        'user_id': 1,
        'heart_rate': 75.0,
        'temperature': 36.8,
        'spo2': 97.0,
        'created_at': '2025-02-09T12:00:00.000Z',
      };
      final r = HealthDataResponse.fromJson(json);
      expect(r.id, 5);
      expect(r.userId, 1);
      expect(r.heartRate, 75.0);
      expect(r.temperature, 36.8);
      expect(r.spo2, 97.0);
      expect(r.createdAt, isNotNull);
      expect(r.createdAt!.toUtc().year, 2025);
    });
  });
}
