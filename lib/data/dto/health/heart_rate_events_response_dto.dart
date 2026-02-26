import 'heart_rate_event_dto.dart';

class HeartRateEventsResponseDto {
  final List<HeartRateEventDto> events;

  const HeartRateEventsResponseDto({
    required this.events,
  });

  factory HeartRateEventsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['events'] ?? json['items'] ?? json['data'];
    final items = <HeartRateEventDto>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          items
              .add(HeartRateEventDto.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return HeartRateEventsResponseDto(events: items);
  }
}
