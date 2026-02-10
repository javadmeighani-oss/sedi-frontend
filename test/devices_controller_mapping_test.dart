import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/devices/logic/devices_controller.dart';

void main() {
  group('deviceStatusLabel', () {
    test('maps active to Active', () {
      expect(deviceStatusLabel('active'), 'Active');
      expect(deviceStatusLabel('Active'), 'Active');
    });
    test('maps revoked to Revoked', () {
      expect(deviceStatusLabel('revoked'), 'Revoked');
      expect(deviceStatusLabel('Revoked'), 'Revoked');
    });
    test('unknown status defaults to Active', () {
      expect(deviceStatusLabel('unknown'), 'Active');
    });
  });

  group('deviceLastSeenLabel', () {
    test('null returns Never', () {
      expect(deviceLastSeenLabel(null), 'Never');
    });
    test('today returns time only', () {
      final now = DateTime.now();
      final t = DateTime(now.year, now.month, now.day, 14, 30);
      expect(deviceLastSeenLabel(t), '14:30');
    });
    test('other day returns date', () {
      final t = DateTime(2025, 2, 9, 12, 0);
      expect(deviceLastSeenLabel(t), '2025-02-09');
    });
  });
}
