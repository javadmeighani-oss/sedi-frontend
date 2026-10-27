import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('internal destinations share a white canvas and card language', () {
    const pages = <String, String>{
      'health':
          'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
      'history':
          'lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart',
      'schedule':
          'lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart',
      'weekly':
          'lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart',
      'devices': 'lib/features/devices/presentation/pages/devices_page.dart',
      'notifications':
          'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
      'profile':
          'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    };

    for (final e in pages.entries) {
      final src = _read(e.value);
      expect(src.contains('A3DestinationSurface.canvas'), isTrue, reason: e.key);
      expect(src.contains('A3DestinationCard'), isTrue, reason: e.key);
      expect(src.contains('gate3PaleOliveBackground'), isFalse, reason: e.key);
      expect(src.contains('A3PageAppBar'), isTrue, reason: e.key);
      expect(src.contains('Directionality'), isTrue, reason: e.key);
    }

    final helper = _read(
      'lib/features/gate3_interactive/presentation/widgets/a3_destination_surface.dart',
    );
    expect(helper.contains('SediPalette.sagePage'), isTrue);
    expect(helper.contains('gate2BorderSubtle'), isTrue);
    expect(helper.contains('radiusLarge'), isTrue);

    final root = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(root.contains('A3DestinationSurface'), isFalse);
    expect(root.contains('A3DestinationCard'), isFalse);
  });
}
