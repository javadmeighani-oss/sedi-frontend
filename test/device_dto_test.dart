import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/data/dto/device_register_request.dart';
import 'package:sedi_app/data/dto/device_public_info.dart';
import 'package:sedi_app/data/dto/devices_list_response.dart';
import 'package:sedi_app/data/dto/device_ingest_request.dart';
import 'package:sedi_app/data/dto/device_ingest_response.dart';

void main() {
  group('DeviceRegisterRequest', () {
    test('toJson includes device_id and optional device_type', () {
      final req = DeviceRegisterRequest(deviceId: 'Sedi001', deviceType: 'heart_rate');
      final j = req.toJson();
      expect(j['device_id'], 'Sedi001');
      expect(j['device_type'], 'heart_rate');
    });

    test('toJson omits device_type when null', () {
      final req = DeviceRegisterRequest(deviceId: 'Sedi002');
      final j = req.toJson();
      expect(j['device_id'], 'Sedi002');
      expect(j.containsKey('device_type'), isFalse);
    });
  });

  group('DevicePublicInfo.fromJson', () {
    test('parses backend device item', () {
      final json = {
        'device_id': 'Sedi001',
        'device_type': 'heart_rate',
        'status': 'active',
        'last_seen_at': '2025-02-09T12:00:00.000Z',
        'created_at': '2025-02-09T10:00:00.000Z',
        'revoked_at': null,
      };
      final d = DevicePublicInfo.fromJson(json);
      expect(d.deviceId, 'Sedi001');
      expect(d.deviceType, 'heart_rate');
      expect(d.status, 'active');
      expect(d.lastSeenAt, isNotNull);
      expect(d.revokedAt, isNull);
    });
  });

  group('DevicesListData.fromJson', () {
    test('parses devices array and count', () {
      final json = {
        'devices': [
          {'device_id': 'Sedi001', 'device_type': 'heart_rate', 'status': 'active', 'created_at': '2025-02-09T10:00:00Z'},
        ],
        'count': 1,
      };
      final data = DevicesListData.fromJson(json);
      expect(data.devices.length, 1);
      expect(data.devices.first.deviceId, 'Sedi001');
      expect(data.count, 1);
    });
  });

  group('DeviceIngestRequest', () {
    test('toJson includes user_id, event_type, payload', () {
      final req = DeviceIngestRequest(
        userId: 1,
        deviceId: 'Sedi001',
        eventType: 'heart_rate',
        payload: {'bpm': 82, 'quality': 'good'},
      );
      final j = req.toJson();
      expect(j['user_id'], 1);
      expect(j['device_id'], 'Sedi001');
      expect(j['event_type'], 'heart_rate');
      expect(j['payload'], {'bpm': 82, 'quality': 'good'});
    });
  });

  group('DeviceIngestResponse.fromJson', () {
    test('parses event_id and dedupe_key', () {
      final json = {'event_id': 123, 'dedupe_key': 'heart_rate:1:2025-02-09T10:30'};
      final r = DeviceIngestResponse.fromJson(json);
      expect(r.eventId, 123);
      expect(r.dedupeKey, 'heart_rate:1:2025-02-09T10:30');
    });
  });
}
