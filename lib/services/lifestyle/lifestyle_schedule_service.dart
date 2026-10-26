import 'package:flutter_timezone/flutter_timezone.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class LifestyleUserEventDto {
  final int id;
  final String title;
  final String? location;
  final String? eventType;
  final String status;
  final String? startsAt;
  final bool reminderEnabled;
  final List<int> reminderOffsets;

  /// 'manual' | 'conversation' | 'system' | 'caregiver' (conversation = created by Sedi from chat).
  final String? source;

  const LifestyleUserEventDto({
    required this.id,
    required this.title,
    this.location,
    this.eventType,
    required this.status,
    this.startsAt,
    this.reminderEnabled = false,
    this.reminderOffsets = const [],
    this.source,
  });

  factory LifestyleUserEventDto.fromJson(Map<String, dynamic> json) {
    final offsets = <int>[];
    final raw = json['reminder_offsets'] ?? json['reminder_offsets_json'];
    if (raw is List) {
      for (final e in raw) {
        final n = int.tryParse('$e');
        if (n != null) offsets.add(n);
      }
    }
    return LifestyleUserEventDto(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString(),
      eventType: json['event_type']?.toString(),
      status: json['status']?.toString() ?? 'scheduled',
      startsAt: json['starts_at']?.toString(),
      reminderEnabled: json['reminder_enabled'] == true,
      reminderOffsets: offsets,
      source: json['source']?.toString(),
    );
  }
}

class LifestyleI8ActionDto {
  final String title;
  final String status;
  final String domain;
  const LifestyleI8ActionDto({
    required this.title,
    required this.status,
    required this.domain,
  });

  factory LifestyleI8ActionDto.fromJson(Map<String, dynamic> json) =>
      LifestyleI8ActionDto(
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? 'upcoming',
        domain: json['domain']?.toString() ?? '',
      );
}

class LifestyleScheduleService {
  final ApiClient _api;
  LifestyleScheduleService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  Future<ApiResponse<List<LifestyleUserEventDto>>> listEvents() {
    return _api.get<List<LifestyleUserEventDto>>(
      '/user/events',
      parser: (data) {
        if (data is! Map) return <LifestyleUserEventDto>[];
        final raw = data['events'];
        if (raw is! List) return <LifestyleUserEventDto>[];
        return raw
            .whereType<Map>()
            .map((e) =>
                LifestyleUserEventDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  Future<ApiResponse<void>> patchReminder({
    required int eventId,
    required bool enabled,
    List<int>? offsets,
  }) {
    return _api.patch<void>(
      '/user/events/$eventId',
      body: {
        'reminder_enabled': enabled,
        if (offsets != null) 'reminder_offsets': offsets,
      },
      parser: (_) => null,
    );
  }

  /// Creates a manual reminder event (same UserEvent authority Sedi uses for chat reminders).
  Future<ApiResponse<void>> createReminder({
    required String title,
    required DateTime startsAt,
    required int offsetMinutes,
  }) async {
    String? tz;
    try {
      tz = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      tz = null;
    }
    final local = DateTime(startsAt.year, startsAt.month, startsAt.day,
        startsAt.hour, startsAt.minute);
    return _api.post<void>(
      '/user/events',
      body: {
        'title': title,
        'event_domain': 'lifestyle',
        'event_type': 'other',
        'starts_at': local.toIso8601String(),
        if (tz != null && tz.isNotEmpty) 'timezone': tz,
        'reminder_enabled': true,
        'reminder_offsets': [offsetMinutes],
        'source': 'manual',
      },
      parser: (_) => null,
    );
  }

  Future<ApiResponse<void>> deleteEvent(int eventId) {
    return _api.delete<void>(
      '/user/events/$eventId',
      parser: (_) => null,
    );
  }

  Future<ApiResponse<List<LifestyleI8ActionDto>>> listI8Actions() {
    return _api.get<List<LifestyleI8ActionDto>>(
      '/lifestyle/schedule-actions',
      parser: (data) {
        if (data is! Map) return <LifestyleI8ActionDto>[];
        final raw = data['items'];
        if (raw is! List) return <LifestyleI8ActionDto>[];
        return raw
            .whereType<Map>()
            .map((e) =>
                LifestyleI8ActionDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }
}
