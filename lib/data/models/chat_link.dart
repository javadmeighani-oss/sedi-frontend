/// R-107 am.3 (Javad 2026-11-21): a link of Sedi's doctor introduction.
///
/// The backend sends `links: [{label, url, kind}]` next to the reply. They are shown as blue underlined lines OUTSIDE the
/// chat bubble and open the original site (the page the doctor's name / address / phone came from). Only a safe https URL
/// is ever accepted here; anything else is dropped (the backend filters too - this is the second wall).
class ChatLink {
  final String label;
  final String url;

  /// `provider` (the page of one doctor) or `search` (a booking-site search page).
  final String kind;

  const ChatLink({required this.label, required this.url, this.kind = 'provider'});

  /// The https [Uri] that may be opened, or null.
  Uri? get uri => safeUri(url);

  static Uri? safeUri(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty || text.length > 600 || text.contains(RegExp(r'\s'))) return null;
    final parsed = Uri.tryParse(text);
    if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty || !parsed.host.contains('.')) {
      return null;
    }
    if (parsed.userInfo.isNotEmpty) return null;
    return parsed;
  }

  static ChatLink? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final url = raw['url']?.toString() ?? '';
    final label = (raw['label']?.toString() ?? '').trim();
    if (label.isEmpty || safeUri(url) == null) return null;
    return ChatLink(label: label, url: url.trim(), kind: raw['kind']?.toString() ?? 'provider');
  }

  /// The links of a response body: unknown / unsafe entries are skipped, at most five, no duplicates.
  static List<ChatLink> listFromJson(dynamic raw) {
    if (raw is! List) return const <ChatLink>[];
    final out = <ChatLink>[];
    final seen = <String>{};
    for (final item in raw) {
      final link = fromJson(item);
      if (link != null && seen.add(link.url)) out.add(link);
      if (out.length >= 5) break;
    }
    return out;
  }
}
