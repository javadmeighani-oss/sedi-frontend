/// DTO for GET /memory/history response.
/// Backend: { "group": "...", "items": [ { "key": "...", "turns": [ ... ] } ] }

class HistoryTurnItem {
  final int id;
  final String createdAt;
  final String userMessage;
  final String? sediResponse;
  final String? language;

  const HistoryTurnItem({
    required this.id,
    required this.createdAt,
    required this.userMessage,
    this.sediResponse,
    this.language,
  });

  factory HistoryTurnItem.fromJson(Map<String, dynamic> json) {
    return HistoryTurnItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      userMessage: json['user_message']?.toString() ?? '',
      sediResponse: json['sedi_response']?.toString(),
      language: json['language']?.toString(),
    );
  }
}

class HistoryGroupItem {
  final String key;
  final List<HistoryTurnItem> turns;

  const HistoryGroupItem({
    required this.key,
    required this.turns,
  });

  factory HistoryGroupItem.fromJson(Map<String, dynamic> json) {
    final turnsList = json['turns'];
    final list = turnsList is List
        ? (turnsList)
            .map((e) => HistoryTurnItem.fromJson(e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList()
        : <HistoryTurnItem>[];
    return HistoryGroupItem(
      key: json['key']?.toString() ?? '',
      turns: list,
    );
  }
}

class HistoryResponse {
  final String group;
  final List<HistoryGroupItem> items;

  const HistoryResponse({
    required this.group,
    required this.items,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'];
    final list = itemsList is List
        ? (itemsList)
            .map((e) => HistoryGroupItem.fromJson(e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList()
        : <HistoryGroupItem>[];
    return HistoryResponse(
      group: json['group']?.toString() ?? 'daily',
      items: list,
    );
  }
}
