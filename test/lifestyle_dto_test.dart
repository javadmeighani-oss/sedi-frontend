import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/dto/lifestyle_data_create.dart';
import 'package:sedi_app/data/dto/lifestyle_context_response.dart';

void main() {
  group('LifestyleDataCreate', () {
    test('toJson includes user_id and all optional fields when set', () {
      final req = LifestyleDataCreate(
        userId: 1,
        sleepHours: 7.5,
        steps: 5000,
        calories: 2000,
        stressLevel: 2,
      );
      final j = req.toJson();
      expect(j['user_id'], 1);
      expect(j['sleep_hours'], 7.5);
      expect(j['steps'], 5000);
      expect(j['calories'], 2000);
      expect(j['stress_level'], 2);
    });

    test('toJson omits optional fields when null', () {
      final req = const LifestyleDataCreate(userId: 2);
      final j = req.toJson();
      expect(j['user_id'], 2);
      expect(j.containsKey('sleep_hours'), isFalse);
      expect(j.containsKey('steps'), isFalse);
      expect(j.containsKey('calories'), isFalse);
      expect(j.containsKey('stress_level'), isFalse);
    });
  });

  group('LifestyleContextResponse.fromJson', () {
    test('parses full object', () {
      final json = {
        'sleep_hours': 7.0,
        'steps': 3000,
        'calories': 1800,
        'stress_level': 1,
      };
      final r = LifestyleContextResponse.fromJson(json);
      expect(r.sleepHours, 7.0);
      expect(r.steps, 3000);
      expect(r.calories, 1800);
      expect(r.stressLevel, 1);
    });

    test('returns empty response for null', () {
      final r = LifestyleContextResponse.fromJson(null);
      expect(r.sleepHours, isNull);
      expect(r.steps, isNull);
      expect(r.calories, isNull);
      expect(r.stressLevel, isNull);
    });

    test('returns empty response for empty map', () {
      final r = LifestyleContextResponse.fromJson({});
      expect(r.sleepHours, isNull);
      expect(r.steps, isNull);
    });

    test('fromApiData with map returns parsed response', () {
      final data = {'sleep_hours': 8.0, 'steps': 10000};
      final r = LifestyleContextResponse.fromApiData(data);
      expect(r, isNotNull);
      expect(r!.sleepHours, 8.0);
      expect(r.steps, 10000);
    });

    test('fromApiData with null returns null', () {
      expect(LifestyleContextResponse.fromApiData(null), isNull);
    });
  });
}
