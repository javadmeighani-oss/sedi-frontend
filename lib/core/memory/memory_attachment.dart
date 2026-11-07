/// One document / image / voice note the user gave Sedi from the chat box (R-021 / M4). Mirrors the backend metadata.
class MemoryAttachment {
  const MemoryAttachment({
    required this.id,
    required this.kind,
    required this.status,
    this.filename,
    this.summary,
    this.transcript,
    this.findings,
    this.analysisText,
    this.confirmed = false,
  });

  final int id;

  /// image | document | audio
  final String kind;

  /// stored | processing | ready | failed | confirmed
  final String status;
  final String? filename;
  final String? summary;
  final String? transcript;
  final Map<String, dynamic>? findings;

  /// R-074 step 4: the backend's plain-words analysis of a read document (flags as printed, trends vs earlier documents).
  final String? analysisText;
  final bool confirmed;

  bool get isAudio => kind == 'audio';

  static MemoryAttachment? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id'];
    if (id is! int) return null;
    final f = m['findings'];
    return MemoryAttachment(
      id: id,
      kind: (m['kind'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      filename: m['filename']?.toString(),
      summary: m['summary']?.toString(),
      transcript: m['transcript']?.toString(),
      findings: f is Map ? Map<String, dynamic>.from(f) : null,
      analysisText: m['analysis'] is Map ? (m['analysis'] as Map)['text']?.toString() : null,
      confirmed: m['confirmed'] == true,
    );
  }
}
