import 'dart:math' as math;

/// Natural, slow word-by-word reveal of Sedi's text (Javad 2026-10-29: "stream the text, very slow and natural").
///
/// UI-only: it never changes what the backend sent, only WHEN each word appears. A pause follows every word, a little
/// longer after a comma and clearly longer after the end of a sentence, like a person writing to a friend.
class NaturalReveal {
  NaturalReveal._();

  /// Base pause after a word (about five words a second).
  static const int baseMs = 170;

  /// Words + the spaces after them (so joining the tokens gives the original text back).
  static List<String> tokens(String text) {
    return [for (final m in RegExp(r'\S+\s*').allMatches(text)) m.group(0)!];
  }

  /// R-120 am.4 (Javad 2026-11-28): the reveal of a doctor introduction. Words as usual, but every line [startsItem] accepts - with its
  /// indented second line - is ONE chunk, so that doctor's card appears whole (number, name, place, phone and link together) in its own
  /// bubble instead of being typed inside the opening bubble. Joining the chunks still gives the original text back.
  static List<String> tokensKeepingItems(String text, bool Function(String line) startsItem) {
    final out = <String>[];
    var plain = StringBuffer();
    void flush() {
      final s = plain.toString();
      plain = StringBuffer();
      if (s.isEmpty) return;
      final lead = RegExp(r'^\s*').firstMatch(s)!.group(0)!;
      final words = tokens(s.substring(lead.length));
      if (lead.isNotEmpty) {
        if (out.isNotEmpty) {
          out[out.length - 1] = out.last + lead;
        } else if (words.isNotEmpty) {
          words[0] = lead + words[0];
        } else {
          out.add(lead);
        }
      }
      out.addAll(words);
    }

    final lines = text.split('\n');
    var inItem = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final nl = i < lines.length - 1 ? '\n' : '';
      if (startsItem(line)) {
        flush();
        out.add(line + nl);
        inItem = true;
        continue;
      }
      if (inItem && line.startsWith(' ') && line.trim().isNotEmpty) {
        out[out.length - 1] = out.last + line + nl; // the indented second line of the same doctor
        continue;
      }
      inItem = false;
      plain.write(line + nl);
    }
    flush();
    return out;
  }

  /// The pause after a whole doctor card.
  static const Duration itemPause = Duration(milliseconds: 650);

  /// The pause AFTER [token]. [total] = how many words the whole text has: a very long answer is revealed faster so that
  /// nobody waits half a minute.
  static Duration gapFor(String token, {int total = 0}) {
    final word = token.trimRight();
    var ms = baseMs;
    final letters = word.runes.length;
    if (letters > 7) ms += 40;
    if (letters <= 2) ms -= 50;
    if (word.endsWith('.') || word.endsWith('!') || word.endsWith('?') || word.endsWith('؟') || word.endsWith('…')) {
      ms += 320;
    } else if (word.endsWith(',') || word.endsWith('،') || word.endsWith('؛') || word.endsWith(';') || word.endsWith(':')) {
      ms += 130;
    }
    if (token.contains('\n')) ms += 220;
    if (total > 160) {
      ms = (ms * 0.45).round();
    } else if (total > 90) {
      ms = (ms * 0.7).round();
    }
    return Duration(milliseconds: ms < 60 ? 60 : ms);
  }

  /// The pause after each of [tokens]. With [maxTotal] the whole reveal is sped up proportionally (never below 30 ms a
  /// word) so that it takes at most that long: used for Sedi's opener when the app opens (Javad 2026-10-30: about 3 s).
  static List<Duration> gapsFor(List<String> tokens, {Duration? maxTotal}) {
    final gaps = [for (final t in tokens) gapFor(t, total: tokens.length)];
    if (maxTotal == null) return gaps;
    final sum = gaps.fold<int>(0, (a, g) => a + g.inMilliseconds);
    if (sum == 0 || sum <= maxTotal.inMilliseconds) return gaps;
    final k = maxTotal.inMilliseconds / sum;
    return [for (final g in gaps) Duration(milliseconds: math.max(30, (g.inMilliseconds * k).round()))];
  }
}
