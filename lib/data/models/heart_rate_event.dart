import '../dto/health/heart_rate_event_dto.dart';

class HeartRateEvent {
  final int bpm;
  final DateTime recordedAt;
  final String? deviceId;
  final String? quality;
  final String? source;
  final String stableKey;

  const HeartRateEvent({
    required this.bpm,
    required this.recordedAt,
    this.deviceId,
    this.quality,
    this.source,
    required this.stableKey,
  });

  factory HeartRateEvent.fromDto(
    HeartRateEventDto dto, {
    String source = 'device_event',
  }) {
    final key = dto.dedupeKey ??
        (dto.id != null
            ? 'id:${dto.id}'
            : '${dto.recordedAt.toUtc().toIso8601String()}:${dto.bpm}:${dto.deviceId ?? ''}');
    return HeartRateEvent(
      bpm: dto.bpm,
      recordedAt: dto.recordedAt,
      deviceId: dto.deviceId,
      quality: dto.quality,
      source: source,
      stableKey: key,
    );
  }
}
