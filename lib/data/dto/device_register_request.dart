/// Request DTO for POST /devices/register.
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (DeviceRegisterRequest)
class DeviceRegisterRequest {
  final String deviceId;
  final String? deviceType;

  const DeviceRegisterRequest({
    required this.deviceId,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      if (deviceType != null && deviceType!.isNotEmpty) 'device_type': deviceType,
    };
  }
}
