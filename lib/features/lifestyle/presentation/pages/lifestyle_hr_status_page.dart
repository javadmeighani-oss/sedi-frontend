import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/lifestyle/lifestyle_health_service.dart';
import '../../../devices/presentation/pages/devices_page.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';

/// The exact state of the gadget's heart-rate data: is it reporting, when did it last report, how much came in today,
/// where the silent stretches were, and how complete this week is. Heart rate only for now.
class LifestyleHrStatusPage extends StatelessWidget {
  final HrDataStatus status;

  const LifestyleHrStatusPage({super.key, required this.status});

  String _d(LifestyleL10n l10n, Object v) =>
      CalendarDateMath.localizeDigitsForLanguage('$v', l10n.lang);

  @override
  Widget build(BuildContext context) {
    final l10n = LifestyleL10n(SediLocaleController.instance.languageCode);
    final active = status.state == 'receiving';
    final color = active ? AppTheme.statusStableOlive : AppTheme.statusNeutralMuted;
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.hrDataStatusTitle),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppTheme.ctaFill,
                foregroundColor: AppTheme.textPrimary,
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DevicesPage()),
              ),
              child: Text(l10n.manageDevice),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            A3DestinationCard(
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.hrStateTitle(status.state),
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        if (status.minutesSinceLast != null)
                          Text(_d(l10n, l10n.hrLastReceivedAgo(status.minutesSinceLast!)),
                              style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (status.state != 'never') ...[
              _heading(l10n.todayLabel),
              A3DestinationCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(l10n.hrReadingsReceived, _d(l10n, status.todayCount)),
                    if (status.firstAt != null && status.lastAt != null)
                      _row(l10n.hrFirstAndLast, _d(l10n, '${status.firstAt} – ${status.lastAt}')),
                    if (status.longestGapMinutes != null)
                      _row(l10n.hrLongestGap, _d(l10n, l10n.hrDuration(status.longestGapMinutes!)),
                          warn: status.longestGapMinutes! >= 60),
                  ],
                ),
              ),
              _heading(l10n.hrThisWeek),
              A3DestinationCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(l10n.hrDaysWithData, _d(l10n, l10n.hrOutOfSeven(status.weekDaysWithData))),
                    _row(l10n.hrAvgPerDay, _d(l10n, status.weekAvgPerDay)),
                  ],
                ),
              ),
              if ((status.longestGapMinutes ?? 0) >= 60 || status.state == 'stale')
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: A3DestinationCard(
                    backgroundColor: AppTheme.gate2CardWhite,
                    child: Text(l10n.hrGapHint,
                        style: const TextStyle(fontSize: 14, height: 1.7, color: AppTheme.textPrimary)),
                  ),
                ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(l10n.noHrData, style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
              child: Text(l10n.hrOnlyHeartRate,
                  style: const TextStyle(fontSize: 13, height: 1.7, color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
      );

  Widget _row(String label, String value, {bool warn = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: warn ? AppTheme.statusChangeAmber : AppTheme.textPrimary)),
          ],
        ),
      );
}
