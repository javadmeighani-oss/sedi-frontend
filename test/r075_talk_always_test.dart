import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/local_notifications_service.dart';

/// R-075 (Javad 2026-11-06): «talk with Sedi» is ALWAYS on the tray notification, within Android's three buttons.
List<String> _ids(List<Map<String, String>> actions, String lang) => resolveNotificationActions(
      data: {'gate4_actions': jsonEncode(actions)},
      language: lang,
    ).map((a) => a.id).toList();

Map<String, String> _a(String id) => {'action_id': id, 'label': id};

void main() {
  test('a follow-up payload without talk gets talk (instead of «later»), three buttons at most', () {
    for (final lang in ['fa', 'ar', 'en']) {
      final ids = _ids([_a('done'), _a('plan_not_done'), _a('later')], lang);
      expect(ids, ['done', 'plan_not_done', 'open_chat'], reason: lang);
    }
  });

  test('a short list just gains talk; a list with talk is untouched', () {
    expect(_ids([_a('done'), _a('plan_not_done')], 'fa'), ['done', 'plan_not_done', 'open_chat']);
    expect(_ids([_a('dislike')], 'en'), ['dislike', 'open_chat']);
    expect(_ids([_a('open_chat'), _a('dislike')], 'fa'), ['open_chat', 'dislike']);
    expect(_ids([_a('done'), _a('plan_not_done'), _a('open_chat')], 'fa'), ['done', 'plan_not_done', 'open_chat']);
  });

  test('Like gives way to talk when the list is full; the talk label comes from the catalog', () {
    expect(_ids([_a('like'), _a('dislike'), _a('later')], 'en'), ['like', 'dislike', 'open_chat']);
    final fa = resolveNotificationActions(data: {'gate4_actions': jsonEncode([_a('done'), _a('plan_not_done')])}, language: 'fa');
    expect(fa.last.id, 'open_chat');
    expect(fa.last.title, 'صحبت با صدی');
    expect(fa.length, lessThanOrEqualTo(3));
  });

  test('an empty payload still falls back to talk + not now', () {
    expect(_ids([], 'fa'), ['open_chat', 'dislike']);
  });
}
