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

  /// 'FREQ=DAILY' | 'FREQ=WEEKLY;BYDAY=MO' - a repeating reminder asked for in chat (DEBT-044); null = one-off.
  final String? recurrenceRule;

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
    this.recurrenceRule,
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
      recurrenceRule: _cleanRule(json['recurrence_rule']),
    );
  }
}

String? _cleanRule(dynamic raw) {
  final v = raw?.toString().trim() ?? '';
  return v.startsWith('FREQ=') ? v : null;
}

/// A medication of the user with its daily dose times (backend `GET /user/medications`).
class LifestyleMedicationDto {
  final int id;
  final String name;
  final List<String> reminderTimes;
  final bool reminderEnabled;

  const LifestyleMedicationDto({
    required this.id,
    required this.name,
    this.reminderTimes = const [],
    this.reminderEnabled = true,
  });

  factory LifestyleMedicationDto.fromJson(Map<String, dynamic> json) {
    final times = <String>[];
    final raw = json['reminder_times'];
    if (raw is List) {
      for (final t in raw) {
        final s = '$t'.trim();
        if (s.isNotEmpty) times.add(s);
      }
    }
    return LifestyleMedicationDto(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      reminderTimes: times,
      reminderEnabled: json['reminder_enabled'] != false,
    );
  }
}

/// Result of marking an occurrence done (R-031).
class ScheduleDoneResult {
  final bool done;

  /// true when the user's memory consent lets Sedi keep it (it is shown to the user).
  final bool inMemory;
  const ScheduleDoneResult({required this.done, required this.inMemory});
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
    String eventDomain = 'lifestyle',
    String eventType = 'other',
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
        'event_domain': eventDomain,
        'event_type': eventType,
        'starts_at': local.toIso8601String(),
        if (tz != null && tz.isNotEmpty) 'timezone': tz,
        'reminder_enabled': true,
        'reminder_offsets': [offsetMinutes],
        'source': 'manual',
      },
      parser: (_) => null,
    );
  }

  Future<ApiResponse<List<LifestyleMedicationDto>>> listMedications() {
    return _api.get<List<LifestyleMedicationDto>>(
      '/user/medications',
      parser: (data) {
        if (data is! Map) return <LifestyleMedicationDto>[];
        final raw = data['medications'];
        if (raw is! List) return <LifestyleMedicationDto>[];
        return raw
            .whereType<Map>()
            .map((e) => LifestyleMedicationDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  Future<ApiResponse<void>> createMedication({
    required String name,
    required List<String> times,
  }) async {
    String? tz;
    try {
      tz = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      tz = null;
    }
    return _api.post<void>(
      '/user/medications',
      body: {
        'name': name,
        'reminder_enabled': true,
        'reminder_times': times,
        if (tz != null && tz.isNotEmpty) 'timezone': tz,
      },
      parser: (_) => null,
    );
  }

  Future<ApiResponse<void>> deleteMedication(int id) {
    return _api.delete<void>('/user/medications/$id', parser: (_) => null);
  }

  /// Marks one occurrence done (or undoes it). The backend records it through its owner and in Sedi's memory (I7).
  Future<ApiResponse<ScheduleDoneResult>> markDone({
    required String kind,
    required int id,
    required String day,
    String? time,
    bool done = true,
  }) {
    return _api.post<ScheduleDoneResult>(
      '/user/schedule/done',
      body: {
        'kind': kind,
        'id': id,
        'day': day,
        if (time != null) 'time': time,
        'done': done,
      },
      parser: (data) {
        final m = data is Map ? data : const {};
        return ScheduleDoneResult(
          done: m['done'] != false,
          inMemory: m['in_memory'] == true,
        );
      },
    );
  }

  /// Occurrence ids already done on [day] (`yyyy-MM-dd`).
  Future<ApiResponse<Set<String>>> listDone(String day) {
    return _api.get<Set<String>>(
      '/user/schedule/done?day=$day',
      parser: (data) {
        if (data is! Map) return <String>{};
        final raw = data['items'];
        if (raw is! List) return <String>{};
        return raw
            .whereType<Map>()
            .map((e) => '${e['id']}')
            .where((s) => s.isNotEmpty && s != 'null')
            .toSet();
      },
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
