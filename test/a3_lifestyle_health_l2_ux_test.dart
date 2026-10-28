import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('L2 Health is a white-card destination with locked HR authority', () {
    final src = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
    );
    expect(src.contains('A3DestinationSurface.canvas'), isTrue);
    expect(src.contains('gate3PaleOliveBackground'), isFalse);
    expect(src.contains('A3DestinationCard'), isTrue);
    expect(src.contains("'7d'"), isTrue);
    expect(src.contains("'30d'"), isTrue);
    expect(src.contains("'1y'"), isTrue);
    expect(src.contains('LifestyleHealthService'), isTrue);
    expect(src.contains('isDeviceReportedStatus'), isTrue);
    expect(src.contains('deviceReportedHrStatusLabel'), isTrue);
    expect(src.contains('statusStableOlive'), isTrue);
    expect(src.contains('statusChangeAmber'), isTrue);
    expect(src.contains('diagnosis'), isFalse);
    expect(src.contains('charts_flutter'), isFalse);
    expect(src.contains('fl_chart'), isFalse);
    expect(src.contains('openLifestyleChat'), isFalse);

    expect(
      A3DestinationSurface.formatIsoTimestamp('not-a-date', 'en'),
      'not-a-date',
    );
    expect(LifestyleL10n('en').latestHr, isNotEmpty);
    expect(LifestyleL10n('fa').isRtl, isTrue);
  });
}
