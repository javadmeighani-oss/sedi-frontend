import '../../features/notifications/presentation/notification_inbox_l10n.dart';
import '../copy/sedi_copy.dart';

/// R-073: what the native tray is told - shared by the arrival renderer and the reason prompt, so both grow the SAME notification.

/// The «not now» reaction itself (not one of the three reasons); the native receiver hands it to Dart behind the grown tray.
const String kTrayDislikeAnswer = '__dislike__';

/// The three answers that all mean «not now» (R-039).
const List<String> kTrayReasons = <String>['busy_now', 'rest_time', 'not_in_mood'];

String trayEscape(String text) =>
    text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('\n', '<br>');

/// The notification keeps ITS OWN text first; after a blank line Sedi's question follows as a bold, coloured heading (a medium
/// pistachio that reads on a light and a dark tray) with its hint below. Android has no horizontal rule in notification text,
/// so the separation is the blank line + the heading (no text-art line). Server text is escaped: it can never inject markup.
String trayPromptHtml({required String originalBody, required String question, required String hint}) {
  final body = originalBody.trim();
  final head = '<b><font color="#7F9E32">${trayEscape(question)}</font></b><br>${trayEscape(hint)}';
  return body.isEmpty ? head : '${trayEscape(body)}<br><br>$head';
}

/// The arguments of the grown notification (rendered natively): own title and text, the question, the three short answers,
/// the two labels of the buttons, the payloads of the «talk» tap and of the answers.
Map<String, Object?> buildGrownArgs({
  required int id,
  required String lang,
  required String title,
  required String body,
  required String channelId,
  required String talkPayload,
  required String answerPayload,
  String? talkLabel,
  String? notNowLabel,
}) {
  final l10n = NotificationInboxL10n(lang);
  final question = l10n.dislikeReasonTitle;
  final hint = l10n.dislikeReasonHint;
  return <String, Object?>{
    'id': id,
    'rtl': lang != 'en',
    'title': title.trim().isEmpty ? question : title,
    'body': body,
    'question': '$question $hint',
    'html': trayPromptHtml(originalBody: body, question: question, hint: hint),
    'talkLabel': (talkLabel ?? '').trim().isEmpty ? SediCopy.t('tray.action.open_chat', lang) : talkLabel,
    'notNowLabel': (notNowLabel ?? '').trim().isEmpty ? SediCopy.t('tray.action.dislike', lang) : notNowLabel,
    'answers': <Map<String, String>>[
      for (final r in kTrayReasons) <String, String>{'id': r, 'label': SediCopy.t('tray.reason.$r', lang)},
    ],
    'channelId': channelId,
    'payload': talkPayload,
    'answerPayload': answerPayload,
  };
}
