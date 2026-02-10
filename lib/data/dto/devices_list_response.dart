/// Parsed data for GET /devices: list of devices + count.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (DevicesListResponse)
import 'device_public_info.dart';

class DevicesListData {
  final List<DevicePublicInfo> devices;
  final int count;

  const DevicesListData({
    required this.devices,
    required this.count,
  });

  factory DevicesListData.fromJson(Map<String, dynamic> json) {
    final list = json['devices'] as List<dynamic>?;
    final devices = list != null
        ? list.map((e) => DevicePublicInfo.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <DevicePublicInfo>[];
    final count = json['count'] is int ? json['count'] as int : devices.length;
    return DevicesListData(devices: devices, count: count);
  }
}
