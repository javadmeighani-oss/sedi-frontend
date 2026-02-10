import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/dto/health_data_response.dart';

void main() {
  group('HealthDataResponse.fromApiData', () {
    test('parses when data is a single object', () {
      final data = {
        'user_id': 1,
        'heart_rate': 72.0,
        'temperature': 36.6,
        'spo2': 98.0,
        'created_at': '2025-02-09T12:00:00.000Z',
      };
      final r = HealthDataResponse.fromApiData(data);
      expect(r, isNotNull);
      expect(r!.userId, 1);
      expect(r.heartRate, 72.0);
      expect(r.temperature, 36.6);
      expect(r.spo2, 98.0);
      expect(r.createdAt, isNotNull);
    });

    test('parses when data is a list - returns first when no created_at', () {
      final data = [
        {'user_id': 1, 'heart_rate': 70.0},
        {'user_id': 1, 'heart_rate': 80.0},
      ];
      final r = HealthDataResponse.fromApiData(data);
      expect(r, isNotNull);
      expect(r!.heartRate, 70.0);
    });

    test('parses when data is a list - picks newest by created_at', () {
      final data = [
        {'user_id': 1, 'heart_rate': 70.0, 'created_at': '2025-02-09T10:00:00.000Z'},
        {'user_id': 1, 'heart_rate': 80.0, 'created_at': '2025-02-09T12:00:00.000Z'},
        {'user_id': 1, 'heart_rate': 75.0, 'created_at': '2025-02-09T11:00:00.000Z'},
      ];
      final r = HealthDataResponse.fromApiData(data);
      expect(r, isNotNull);
      expect(r!.heartRate, 80.0);
      expect(r.createdAt, isNotNull);
      expect(r.createdAt!.toUtc().hour, 12);
    });

    test('returns null when data is null', () {
      expect(HealthDataResponse.fromApiData(null), isNull);
    });

    test('returns null when data is empty list', () {
      expect(HealthDataResponse.fromApiData([]), isNull);
    });
  });
}
