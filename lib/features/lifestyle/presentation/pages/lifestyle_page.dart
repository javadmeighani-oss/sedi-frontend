import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../services/lifestyle/lifestyle_schedule_service.dart';
import '../../../gate3_interactive/presentation/gate3_assistant_starter_bus.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../domain/schedule_today.dart';
import '../lifestyle_l10n.dart';
import 'lifestyle_exercise_page.dart';
import 'lifestyle_health_page.dart';
import 'lifestyle_history_page.dart';
import 'lifestyle_nutrition_page.dart';
import 'lifestyle_schedule_page.dart';

/// A3 Lifestyle hub — exactly five primary sections. Old sleep/water/mood UI retired here.
class LifestylePage extends StatefulWidget {
  const LifestylePage({super.key});

  @override
  State<LifestylePage> createState() => _LifestylePageState();
}

class _LifestylePageState extends State<LifestylePage> {
  static const Color _canvas = Color(0xFFDCE0C0); // Soft Sage (= A3DestinationSurface.canvas)

  /// Live one-line summary of today (R-031); null until loaded or when it cannot be read.
  ScheduleDaySummary? _summary;

  @override
  void initState() {
    super.initState();
    // Under `flutter test` there is no backend: the hub keeps its static subtitles.
    if (Platform.environment['FLUTTER_TEST'] != 'true') _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final svc = LifestyleScheduleService();
      final now = DateTime.now();
      final ev = await svc.listEvents();
      final md = await svc.listMedications();
      final dn = await svc.listDone(isoDay(now));
      if (!mounted || !ev.ok) return;
      final items = buildToday(
        events: ev.data ?? const [],
        medications: md.data ?? const [],
        doneIds: dn.data ?? <String>{},
        today: now,
      );
      setState(() => _summary = summarize(items, now));
    } catch (_) {
      // fail-open: the static hub stays
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LifestyleL10n(SediLocaleController.instance.languageCode);
    final summary = _summary;
    final cards = <_HubCard>[
      _HubCard(
        l10n.health,
        l10n.healthSubtitle,
        Icons.favorite_border,
        const LifestyleHealthPage(),
      ),
      _HubCard(
        l10n.myHistory,
        l10n.historySubtitle,
        Icons.history,
        const LifestyleHistoryPage(),
      ),
      _HubCard(
        l10n.mySchedule,
        summary == null
            ? l10n.scheduleSubtitle
            : l10n.hubScheduleLine(summary.total - summary.done),
        Icons.event_note_outlined,
        const LifestyleSchedulePage(),
      ),
      _HubCard(
        l10n.nutritionPlan,
        l10n.nutritionSubtitle,
        Icons.restaurant_outlined,
        const LifestyleNutritionPage(),
      ),
      _HubCard(
        l10n.exercisePlan,
        l10n.exerciseSubtitle,
        Icons.directions_run_outlined,
        const LifestyleExercisePage(),
      ),
    ];

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.title),
          backgroundColor: _canvas,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          itemCount: cards.length + (summary == null ? 0 : 1),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            if (summary != null && i == 0) {
              return _hubTodayCard(summary, l10n);
            }
            final c = cards[summary == null ? i : i - 1];
            return _LifestyleHubDestinationCard(card: c);
          },
        ),
      ),
    );
  }
}

/// "Today" summary: how many things, how many done, what is next (same data as My Schedule).
Widget _hubTodayCard(ScheduleDaySummary s, LifestyleL10n l10n) {
    final fraction = s.total == 0 ? 0.0 : s.done / s.total;
    final next = s.next;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SediPalette.pistachio300, SediPalette.pistachio500],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SediPalette.pistachio700.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.today,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2B3316)),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.hubToday(s.total, s.done),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF1B2208)),
          ),
          if (s.total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.55),
                valueColor: const AlwaysStoppedAnimation<Color>(SediPalette.pistachio900),
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.hubNext(next.title, l10n.timeText(next.when)),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B2208)),
            ),
          ],
        ],
      ),
    );
}

class _LifestyleHubDestinationCard extends StatelessWidget {
  final _HubCard card;

  const _LifestyleHubDestinationCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.gate2CardWhite,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => card.page),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.gate2CardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.gate2BorderSubtle,
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(card.icon, color: AppTheme.gate2ButtonOlive, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  const _HubCard(this.title, this.subtitle, this.icon, this.page);
}

/// Opens canonical existing A3 chat (presentation CTA only).
/// Pops nested Lifestyle routes back to root A3 and inserts an assistant
/// starter message (composer stays empty). Never nested A3; never auto-sends.
void openLifestyleChat(BuildContext context, {String? starterMessage}) {
  final starter = starterMessage?.trim();
  if (starter != null && starter.isNotEmpty) {
    Gate3AssistantStarterBus.instance.publish(starter);
  }
  Navigator.of(context).popUntil((route) => route.isFirst);
}
