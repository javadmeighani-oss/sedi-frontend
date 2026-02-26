class HeartRateEventDto {
  final int? id;
  final int? userId;
  final String? deviceId;
  final String eventType;
  final int bpm;
  final String? quality;
  final DateTime recordedAt;
  final DateTime? receivedAt;
  final String? dedupeKey;

  const HeartRateEventDto({
    this.id,
    this.userId,
    this.deviceId,
    required this.eventType,
    required this.bpm,
    this.quality,
    required this.recordedAt,
    this.receivedAt,
    this.dedupeKey,
  });

  factory HeartRateEventDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : json['payload_json'] is Map
            ? Map<String, dynamic>.from(json['payload_json'] as Map)
            : <String, dynamic>{};
    final bpmRaw = payload['bpm'] ?? json['bpm'];
    final bpm =
        bpmRaw is int ? bpmRaw : int.tryParse(bpmRaw?.toString() ?? '') ?? 0;
    final recordedRaw =
        json['recorded_at']?.toString() ?? json['created_at']?.toString();
    final recordedAt = DateTime.tryParse(recordedRaw ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final receivedAt = DateTime.tryParse(json['received_at']?.toString() ?? '');
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final userRaw = json['user_id'];
    final userId =
        userRaw is int ? userRaw : int.tryParse(userRaw?.toString() ?? '');

    return HeartRateEventDto(
      id: id,
      userId: userId,
      deviceId: json['device_id']?.toString(),
      eventType: json['event_type']?.toString() ?? 'heart_rate',
      bpm: bpm,
      quality: payload['quality']?.toString() ?? json['quality']?.toString(),
      recordedAt: recordedAt,
      receivedAt: receivedAt,
      dedupeKey: json['dedupe_key']?.toString(),
    );
  }
}
