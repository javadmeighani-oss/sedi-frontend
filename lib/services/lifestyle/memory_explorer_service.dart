import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

/// H1: the user's memory explorer (backend `/memory/calendar|day|search|turns|day-notes`, owned by I7).
/// Every date is an ISO `YYYY-MM-DD` in the user's backend-resolved local day; the device never infers a day.

int _int(dynamic v) => int.tryParse('$v') ?? 0;

class MemoryTurnDto {
  final int id;
  final String time;
  final String userMessage;
  final String? sediResponse;

  const MemoryTurnDto({
    required this.id,
    required this.time,
    required this.userMessage,
    this.sediResponse,
  });

  factory MemoryTurnDto.fromJson(Map<String, dynamic> j) => MemoryTurnDto(
        id: _int(j['id']),
        time: j['time']?.toString() ?? '',
        userMessage: j['user_message']?.toString() ?? '',
        sediResponse: j['sedi_response']?.toString(),
      );
}

class MemoryEventDto {
  final int id;
  final String title;
  final bool lifeEvent;
  final String? startsAt;

  const MemoryEventDto({
    required this.id,
    required this.title,
    this.lifeEvent = false,
    this.startsAt,
  });

  /// HH:MM of the stored start (device-neutral text slice; the backend stores the user's wall clock for events).
  String get timeLabel {
    final s = startsAt ?? '';
    final i = s.indexOf('T');
    return i >= 0 && s.length >= i + 6 ? s.substring(i + 1, i + 6) : '';
  }

  factory MemoryEventDto.fromJson(Map<String, dynamic> j) => MemoryEventDto(
        id: _int(j['id']),
        title: j['title']?.toString() ?? '',
        lifeEvent: j['life_event'] == true,
        startsAt: j['starts_at']?.toString(),
      );
}

class MemoryNoteDto {
  final int id;

  /// 'note' | 'correction'
  final String kind;
  final String text;

  const MemoryNoteDto({required this.id, required this.kind, required this.text});

  bool get isCorrection => kind == 'correction';

  factory MemoryNoteDto.fromJson(Map<String, dynamic> j) => MemoryNoteDto(
        id: _int(j['id']),
        kind: j['kind']?.toString() ?? 'note',
        text: j['text']?.toString() ?? '',
      );
}

class MemoryFactDto {
  final int id;
  final String value;
  final bool editable;

  const MemoryFactDto({required this.id, required this.value, this.editable = false});

  factory MemoryFactDto.fromJson(Map<String, dynamic> j) => MemoryFactDto(
        id: _int(j['id']),
        value: j['value']?.toString() ?? '',
        editable: j['editable'] == true,
      );
}

class MemorySummaryChips {
  final List<String> topics;
  final List<String> wellbeing;
  final int planDone;
  final int planTotal;
  final int userDone;

  const MemorySummaryChips({
    this.topics = const [],
    this.wellbeing = const [],
    this.planDone = 0,
    this.planTotal = 0,
    this.userDone = 0,
  });

  bool get isEmpty =>
      topics.isEmpty && wellbeing.isEmpty && planTotal == 0 && userDone == 0;

  factory MemorySummaryChips.fromJson(Object? raw) {
    if (raw is! Map) return const MemorySummaryChips();
    List<String> strings(Object? v) =>
        v is List ? v.map((e) => '$e').toList(growable: false) : const [];
    return MemorySummaryChips(
      topics: strings(raw['topics']),
      wellbeing: strings(raw['wellbeing']),
      planDone: _int(raw['plan_done']),
      planTotal: _int(raw['plan_total']),
      userDone: _int(raw['user_done']),
    );
  }
}

class MemoryDayDto {
  final String date;
  final int daysAgo;

  /// True only for days inside the 30-day retention window: raw chat text is returned and editable.
  final bool rawVisible;
  final bool consent;
  final List<MemoryTurnDto> turns;
  final String summaryText;
  final MemorySummaryChips chips;
  final List<MemoryEventDto> events;
  final List<MemoryNoteDto> notes;
  final List<MemoryFactDto> facts;

  const MemoryDayDto({
    required this.date,
    required this.daysAgo,
    required this.rawVisible,
    required this.consent,
    this.turns = const [],
    this.summaryText = '',
    this.chips = const MemorySummaryChips(),
    this.events = const [],
    this.notes = const [],
    this.facts = const [],
  });

  factory MemoryDayDto.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) f) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => f(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <T>[];
    final summary = j['summary'] is Map ? Map<String, dynamic>.from(j['summary'] as Map) : const <String, dynamic>{};
    return MemoryDayDto(
      date: j['date']?.toString() ?? '',
      daysAgo: _int(j['days_ago']),
      rawVisible: j['raw_visible'] == true,
      consent: j['consent'] == true,
      turns: list(j['turns'], MemoryTurnDto.fromJson),
      summaryText: summary['text']?.toString() ?? '',
      chips: MemorySummaryChips.fromJson(summary['chips']),
      events: list(j['events'], MemoryEventDto.fromJson),
      notes: list(j['notes'], MemoryNoteDto.fromJson),
      facts: list(j['facts'], MemoryFactDto.fromJson),
    );
  }
}

class MemorySearchHit {
  /// 'chat' | 'summary' | 'event' | 'note' | 'fact'
  final String type;
  final String date;
  final String snippet;

  const MemorySearchHit({required this.type, required this.date, required this.snippet});

  factory MemorySearchHit.fromJson(Map<String, dynamic> j) => MemorySearchHit(
        type: j['type']?.toString() ?? 'chat',
        date: j['date']?.toString() ?? '',
        snippet: j['snippet']?.toString() ?? '',
      );
}

class MemoryExplorerService {
  final ApiClient _api;

  MemoryExplorerService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Days in [from, to] that hold a memory (counts only) -> set of ISO dates.
  Future<Set<String>> daysWithMemory({required String from, required String to}) async {
    final res = await _api.getRaw('/memory/calendar', queryParams: {'from': from, 'to': to});
    final out = <String>{};
    final days = res.ok ? res.data?['days'] : null;
    if (days is List) {
      for (final d in days) {
        if (d is Map && d['date'] != null) out.add('${d['date']}');
      }
    }
    return out;
  }

  Future<ApiResponse<MemoryDayDto>> day(String iso) {
    return _api.get<MemoryDayDto>(
      '/memory/day',
      queryParams: {'date': iso},
      parser: (v) => v is Map ? MemoryDayDto.fromJson(Map<String, dynamic>.from(v)) : null,
    );
  }

  Future<List<MemorySearchHit>> search(String q, {String? from, String? to}) async {
    final res = await _api.getRaw('/memory/search', queryParams: {
      'q': q,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    final raw = res.ok ? res.data?['results'] : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MemorySearchHit.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<ApiResponse<void>> editTurn(int id, {String? userMessage, String? sediResponse}) {
    return _api.patch<void>(
      '/memory/turns/$id',
      body: {
        if (userMessage != null) 'user_message': userMessage,
        if (sediResponse != null) 'sedi_response': sediResponse,
      },
      parser: (_) => null,
    );
  }

  Future<ApiResponse<void>> deleteTurn(int id) =>
      _api.delete<void>('/memory/turns/$id', parser: (_) => null);

  /// [kind] 'note' (about the day) or 'correction' (placed beside an old summary; the summary is never rewritten).
  Future<ApiResponse<void>> addNote({required String day, required String text, String kind = 'note'}) {
    return _api.post<void>(
      '/memory/day-notes',
      body: {'day': day, 'text': text, 'kind': kind},
      parser: (_) => null,
    );
  }

  Future<ApiResponse<void>> editNote(int id, String text) =>
      _api.patch<void>('/memory/day-notes/$id', body: {'text': text}, parser: (_) => null);

  Future<ApiResponse<void>> deleteNote(int id) =>
      _api.delete<void>('/memory/day-notes/$id', parser: (_) => null);

  Future<ApiResponse<void>> editFact(int id, String value) =>
      _api.patch<void>('/memory/facts/$id', body: {'value': value}, parser: (_) => null);

  Future<ApiResponse<void>> deleteFact(int id) =>
      _api.delete<void>('/memory/facts/$id', parser: (_) => null);

  Future<ApiResponse<void>> deleteEvent(int id) =>
      _api.delete<void>('/memory/events/$id', parser: (_) => null);
}
