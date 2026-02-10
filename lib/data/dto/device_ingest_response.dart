/// Parsed data for POST /device/ingest response (data payload).
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md (DeviceIngestResponse)
class DeviceIngestResponse {
  final int? eventId;
  final String? dedupeKey;

  const DeviceIngestResponse({
    this.eventId,
    this.dedupeKey,
  });

  factory DeviceIngestResponse.fromJson(Map<String, dynamic> json) {
    int? eventId;
    if (json['event_id'] != null) {
      eventId = json['event_id'] is int ? json['event_id'] as int : int.tryParse(json['event_id'].toString());
    }
    return DeviceIngestResponse(
      eventId: eventId,
      dedupeKey: json['dedupe_key'] as String?,
    );
  }
}
