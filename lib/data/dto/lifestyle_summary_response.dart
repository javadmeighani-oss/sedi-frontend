/// DTO for GET /lifestyle/summary response.
/// Backend: generated_at, language, sections[{title, body, items?, sources?}], sources_used{facts_count, memory_days_covered}
/// Stage 17.4: section.sources for "Why this?" explainability.

class LifestyleSummarySource {
  final String type;
  final String id;
  final String label;
  final String? ts;

  const LifestyleSummarySource({
    required this.type,
    required this.id,
    required this.label,
    this.ts,
  });

  factory LifestyleSummarySource.fromJson(Map<String, dynamic> json) {
    return LifestyleSummarySource(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      ts: json['ts']?.toString(),
    );
  }
}

class LifestyleSummarySection {
  final String title;
  final String body;
  final List<String>? items;
  final List<LifestyleSummarySource>? sources;

  const LifestyleSummarySection({
    required this.title,
    required this.body,
    this.items,
    this.sources,
  });

  factory LifestyleSummarySection.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'];
    final list = itemsList is List
        ? (itemsList).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : null;
    final sourcesList = json['sources'];
    final sources = sourcesList is List
        ? (sourcesList)
            .map((e) => LifestyleSummarySource.fromJson(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .where((s) => s.type.isNotEmpty)
            .toList()
        : null;
    return LifestyleSummarySection(
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      items: list,
      sources: (sources != null && sources.isNotEmpty) ? sources : null,
    );
  }
}

class LifestyleSummaryResponse {
  final String generatedAt;
  final String language;
  final List<LifestyleSummarySection> sections;
  final int factsCount;
  final int memoryDaysCovered;

  const LifestyleSummaryResponse({
    required this.generatedAt,
    required this.language,
    required this.sections,
    required this.factsCount,
    required this.memoryDaysCovered,
  });

  factory LifestyleSummaryResponse.fromJson(Map<String, dynamic> json) {
    final sectionsList = json['sections'];
    final sectionList = sectionsList is List
        ? (sectionsList)
            .map((e) => LifestyleSummarySection.fromJson(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList()
        : <LifestyleSummarySection>[];
    final sources = json['sources_used'];
    final sourcesMap = sources is Map<String, dynamic> ? sources : <String, dynamic>{};
    return LifestyleSummaryResponse(
      generatedAt: json['generated_at']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      sections: sectionList,
      factsCount: sourcesMap['facts_count'] is int
          ? sourcesMap['facts_count'] as int
          : int.tryParse(sourcesMap['facts_count']?.toString() ?? '0') ?? 0,
      memoryDaysCovered: sourcesMap['memory_days_covered'] is int
          ? sourcesMap['memory_days_covered'] as int
          : int.tryParse(sourcesMap['memory_days_covered']?.toString() ?? '0') ?? 0,
    );
  }

  static LifestyleSummaryResponse? fromApiData(Object? data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return LifestyleSummaryResponse.fromJson(data);
    return null;
  }
}
