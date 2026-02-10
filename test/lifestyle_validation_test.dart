import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/logic/lifestyle_validation.dart';

void main() {
  group('validateSleepHours', () {
    test('accepts 0 and 24', () {
      expect(validateSleepHours(0), isNull);
      expect(validateSleepHours(24), isNull);
    });
    test('accepts value in range', () {
      expect(validateSleepHours(7.5), isNull);
    });
    test('rejects below 0', () {
      expect(validateSleepHours(-0.1), isNotNull);
    });
    test('rejects above 24', () {
      expect(validateSleepHours(24.1), isNotNull);
    });
    test('accepts null', () {
      expect(validateSleepHours(null), isNull);
    });
  });

  group('validateSteps', () {
    test('accepts 0 and 100000', () {
      expect(validateSteps(0), isNull);
      expect(validateSteps(100000), isNull);
    });
    test('rejects negative', () {
      expect(validateSteps(-1), isNotNull);
    });
    test('rejects above 100000', () {
      expect(validateSteps(100001), isNotNull);
    });
    test('accepts null', () {
      expect(validateSteps(null), isNull);
    });
  });

  group('validateCalories', () {
    test('accepts 0 and 20000', () {
      expect(validateCalories(0), isNull);
      expect(validateCalories(20000), isNull);
    });
    test('rejects negative', () {
      expect(validateCalories(-1), isNotNull);
    });
    test('rejects above 20000', () {
      expect(validateCalories(20001), isNotNull);
    });
    test('accepts null', () {
      expect(validateCalories(null), isNull);
    });
  });

  group('validateStressLevel', () {
    test('accepts 0 and 10', () {
      expect(validateStressLevel(0), isNull);
      expect(validateStressLevel(10), isNull);
    });
    test('rejects negative', () {
      expect(validateStressLevel(-1), isNotNull);
    });
    test('rejects above 10', () {
      expect(validateStressLevel(11), isNotNull);
    });
    test('accepts null', () {
      expect(validateStressLevel(null), isNull);
    });
  });
}
