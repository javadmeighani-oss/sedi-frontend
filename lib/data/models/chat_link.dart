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

  /// R-120 am.2 (Javad 2026-11-26): ONE bubble - each doctor's line (name — specialty), his place, an optional note («farther, but worth
  /// the visit») and RIGHT UNDER it the link text to his page. Empty for older replies (they keep the lines below the bubble).
  final String title;
  final String location;
  final String note;
  final String linkText;

  /// R-120 am.3 (Javad 2026-11-27): the doctor's number in the introduction (1..5) and the phone his site publishes.
  final int index;
  final String phone;

  /// R-120 am.4 (Javad 2026-11-28): while Sedi is typing, how many pieces of this doctor's card are shown ([revealPieces]: the words of his
  /// title, of his place, his phone, the words of the note, then the link). -1 = the whole card (history, finished replies).
  final int revealUnits;

  const ChatLink({
    required this.label,
    required this.url,
    this.kind = 'provider',
    this.title = '',
    this.location = '',
    this.note = '',
    this.linkText = '',
    this.index = 0,
    this.phone = '',
    this.revealUnits = -1,
  });

  /// Words + the spaces after them (joined they give the text back).
  static List<String> words(String text) => [for (final m in RegExp(r'\S+\s*').allMatches(text)) m.group(0)!];

  /// The card's pieces in the order they are typed: title words, place words, the phone (whole), note words, the link (whole).
  List<String> get revealPieces => [
        ...words(title),
        ...words(location),
        if (phone.isNotEmpty) phone,
        ...words(note),
        linkText.isNotEmpty ? linkText : label,
      ];

  /// This card typed up to [units] pieces (the same doctor; the full fields stay for matching his «•» line).
  ChatLink revealedTo(int units) => ChatLink(
        label: label,
        url: url,
        kind: kind,
        title: title,
        location: location,
        note: note,
        linkText: linkText,
        index: index,
        phone: phone,
        revealUnits: units,
      );

  /// The phone as a dialable `tel:` URI (digits and a leading +, Persian/Arabic digits folded), or null.
  Uri? get phoneUri {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final ch in phone.split('')) {
      final i = fa.indexOf(ch) >= 0 ? fa.indexOf(ch) : ar.indexOf(ch);
      if (i >= 0) {
        buf.write(i);
      } else if (RegExp(r'[0-9]').hasMatch(ch) || (ch == '+' && buf.isEmpty)) {
        buf.write(ch);
      }
    }
    final digits = buf.toString();
    return digits.replaceAll('+', '').length >= 5 ? Uri(scheme: 'tel', path: digits) : null;
  }

  /// A doctor shown INSIDE the bubble with his link under him.
  bool get inBubble => kind == 'provider' && title.isNotEmpty;

  /// The doctor's name as the reply's «•» line starts with it (the title is «name — specialty»).
  String get doctorName => title.split(' — ').first.trim();

  /// R-120 am.4: [line] is this doctor's «•» line of the reply text.
  bool startsDoctorLine(String line) => inBubble && bulletNames(line, doctorName);

  /// [line] is a «•» line whose name is exactly [name]: after the name comes the end of the line or a delimiter («—», «،», «,», «(»…),
  /// never more name - «دکتر علی» does not match the line of «دکتر علی رضایی» (Codex P2, FE PR 37).
  static bool bulletNames(String line, String name) {
    // only the FIRST line: a reveal chunk carries the doctor's indented second line too (Codex P2, FE PR 37 round 2)
    final trimmed = line.trimLeft().split('\n').first;
    final wanted = name.trim();
    if (wanted.isEmpty || !trimmed.startsWith('•')) return false;
    final body = trimmed.substring(1).trimLeft();
    if (!body.startsWith(wanted)) return false;
    final rest = body.substring(wanted.length).trimLeft();
    return rest.isEmpty || RegExp(r'^[—–\-،,:;(|/]').hasMatch(rest);
  }

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
    String text(String key) => (raw[key]?.toString() ?? '').trim();
    return ChatLink(
      label: label,
      url: url.trim(),
      kind: raw['kind']?.toString() ?? 'provider',
      title: text('title'),
      location: text('location'),
      note: text('note'),
      linkText: text('link_text'),
      index: int.tryParse(raw['index']?.toString() ?? '') ?? 0,
      phone: text('phone'),
    );
  }

  /// The links of a response body: unknown / unsafe entries are skipped, at most six (five near doctors + one «worth the trip»), no duplicates.
  static List<ChatLink> listFromJson(dynamic raw) {
    if (raw is! List) return const <ChatLink>[];
    final out = <ChatLink>[];
    final seen = <String>{};
    for (final item in raw) {
      final link = fromJson(item);
      if (link != null && seen.add(link.url)) out.add(link);
      if (out.length >= 6) break;
    }
    return out;
  }
}
