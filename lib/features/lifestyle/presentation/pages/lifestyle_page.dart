import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/gate3_assistant_starter_bus.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
import '../../domain/schedule_today.dart';
import '../../logic/lifestyle_summary_cache.dart';
import '../lifestyle_l10n.dart';
import 'lifestyle_exercise_page.dart';
import 'lifestyle_health_page.dart';
import 'lifestyle_history_page.dart';
import 'lifestyle_nutrition_page.dart';
import 'lifestyle_schedule_page.dart';

/// A3 Lifestyle hub — exactly five primary sections. Old sleep/water/mood UI retired here.
/// Pilot V1 (R-034/R-035): glass bento cards, icon first; the Sedi sphere sits on the start side of the title.
class LifestylePage extends StatefulWidget {
  const LifestylePage({super.key});

  @override
  State<LifestylePage> createState() => _LifestylePageState();
}

class _LifestylePageState extends State<LifestylePage> {
  static const Color _canvas = Color(0xFFDCE0C0); // Soft Sage (= A3DestinationSurface.canvas)

  static const double _todayHeight = 140;
  static const double _gap = 12;

  /// Live one-line summary of today (R-031): the one loaded earlier today (A3 asks for it in the background) or the
  /// fresh one; null when it cannot be read.
  ScheduleDaySummary? _summary = LifestyleSummaryCache.today();

  /// True while the first read is on its way and there is nothing to show yet: the card's place is kept (a skeleton)
  /// so the hub never jumps when the answer arrives.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Under `flutter test` there is no backend: the hub keeps its static subtitles.
    if (Platform.environment['FLUTTER_TEST'] != 'true') {
      _loading = _summary == null;
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    final fresh = await LifestyleSummaryCache.refresh(); // fail-open: null keeps the static hub
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (fresh != null) _summary = fresh;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LifestyleL10n(SediLocaleController.instance.languageCode);
    final summary = _summary;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    final health = _HubCard(
      l10n.health,
      l10n.healthSubtitle,
      Icons.favorite_border,
      const LifestyleHealthPage(),
      _HubTint.health,
    );
    final history = _HubCard(
      l10n.myHistory,
      l10n.historySubtitle,
      Icons.history,
      const LifestyleHistoryPage(),
      _HubTint.history,
    );
    final schedule = _HubCard(
      l10n.mySchedule,
      // nothing planned today: the plain subtitle (never "everything is done" next to "no plan today")
      summary == null || summary.total == 0
          ? l10n.scheduleSubtitle
          : l10n.hubScheduleLine(summary.total - summary.done),
      Icons.event_available_outlined,
      const LifestyleSchedulePage(),
      _HubTint.schedule,
    );
    final nutrition = _HubCard(
      l10n.nutritionPlan,
      l10n.nutritionSubtitle,
      Icons.restaurant_outlined,
      const LifestyleNutritionPage(),
      _HubTint.nutrition,
    );
    final exercise = _HubCard(
      l10n.exercisePlan,
      l10n.exerciseSubtitle,
      Icons.fitness_center_outlined,
      const LifestyleExercisePage(),
      _HubTint.exercise,
    );

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _canvas,
        extendBodyBehindAppBar: true,
        appBar: A3PageAppBar(
          // R-035: the small Sedi sphere sits on the START side of the title (right in fa/ar, left in en).
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SediHologramOrb(
                state: Gate3InteractionState.idle,
                diameter: 38,
                showRings: false,
                animate: false,
                keyedLogo: false,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: SediGlass.inkDeep,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SediSceneBackdrop(),
            LayoutBuilder(
              builder: (context, box) {
                // Everything fits ONE screen and never scrolls: the cards share the height that is left.
                final height = math.max(box.maxHeight - top - 24, 0.0);
                return Padding(
                  padding: EdgeInsets.fromLTRB(16, top, 16, 24),
                  child: SizedBox(
                      height: height,
                      child: Column(
                        children: [
                          if (summary != null) ...[
                            SizedBox(
                              height: _todayHeight,
                              child: _hubTodayCard(summary, l10n),
                            ),
                            const SizedBox(height: _gap),
                          ] else if (_loading) ...[
                            const SizedBox(
                              height: _todayHeight,
                              child: _HubTodaySkeleton(),
                            ),
                            const SizedBox(height: _gap),
                          ],
                          Expanded(
                            flex: 286,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _LifestyleHubDestinationCard(
                                    card: health,
                                    tall: true,
                                  ),
                                ),
                                const SizedBox(width: _gap),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _LifestyleHubDestinationCard(
                                          card: history,
                                        ),
                                      ),
                                      const SizedBox(height: _gap),
                                      Expanded(
                                        child: _LifestyleHubDestinationCard(
                                          card: schedule,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: _gap),
                          Expanded(
                            flex: 150,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _LifestyleHubDestinationCard(
                                    card: nutrition,
                                  ),
                                ),
                                const SizedBox(width: _gap),
                                Expanded(
                                  child: _LifestyleHubDestinationCard(
                                    card: exercise,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// "Today" summary: the date as the small line, ONE sentence (never the word twice), a real progress ring
/// and what is next - the same data as My Schedule. Shown only once that data is loaded.
Widget _hubTodayCard(ScheduleDaySummary s, LifestyleL10n l10n) {
  final now = DateTime.now();
  final lang = SediLocaleController.instance.languageCode;
  final date =
      '${l10n.weekdayShort(now.weekday)} ${CalendarDateMath.formatIsoForLanguage(isoDay(now), lang)}';
  final fraction = s.total == 0 ? 0.0 : s.done / s.total;
  final next = s.next;
  const ink = Color(0xFF1B2208);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [SediPalette.pistachio300, SediPalette.pistachio500],
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.white.withOpacity(0.7)),
      boxShadow: [
        BoxShadow(
          color: SediPalette.pistachio700.withOpacity(0.30),
          blurRadius: 36,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: CustomPaint(
            painter: _TodayRingPainter(fraction),
            child: Center(
              child: s.total == 0
                  ? const Icon(Icons.wb_sunny_outlined,
                      size: 34, color: Color(0xFF2B3A0E))
                  : Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${l10n.digits(s.done)}/${l10n.digits(s.total)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 15, color: Color(0xFF2B3316)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B3316),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                l10n.hubToday(s.total, s.done),
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 17, color: ink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.hubNext(next.title, l10n.timeText(next.when)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _TodayRingPainter extends CustomPainter {
  final double fraction;

  const _TodayRingPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withOpacity(0.35));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = Colors.white.withOpacity(0.75),
    );
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = SediPalette.pistachio900,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TodayRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

class _LifestyleHubDestinationCard extends StatelessWidget {
  final _HubCard card;

  /// The tall Health card: a larger icon tile and a soft decorative wave (decoration only, not data).
  final bool tall;

  const _LifestyleHubDestinationCard({required this.card, this.tall = false});

  @override
  Widget build(BuildContext context) {
    // The card lives in a share of the screen that gets smaller when the today card is on top: it adapts instead of
    // overflowing by a fraction of a pixel (phone test 2026-10-30).
    return LayoutBuilder(builder: (context, box) => _build(context, box.maxHeight, box.maxWidth));
  }

  Widget _build(BuildContext context, double height, double width) {
    final radius = BorderRadius.circular(30);
    final snug = !tall && height < 150;
    final tight = !tall && height < 128;
    final tile = tall ? 58.0 : (snug ? 40.0 : 50.0);
    final pad = snug ? 12.0 : 14.0;
    final titleText = Text(
      card.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1F2A09),
      ),
    );
    final subtitleText = Text(
      card.subtitle,
      maxLines: tight ? 1 : (snug ? 2 : 3),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF4B5530),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      label: card.title,
      excludeSemantics: true,
      child: SediGlass.blur(
        radius: radius,
        sigma: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: card.tint.colors,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF48551F).withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => card.page),
              ),
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: tile,
                      height: tile,
                      decoration: SediGlass.tile(),
                      child: Icon(
                        card.icon,
                        size: 30,
                        color: SediGlass.ink,
                      ),
                    ),
                    if (tall) ...[
                      const Expanded(child: _SoftWave()),
                      titleText,
                      const SizedBox(height: 3),
                      subtitleText,
                    ] else
                      // whatever font the phone has, the words only scale down - they never overflow the card
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.bottomStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.bottomStart,
                            child: SizedBox(
                              width: math.max(width - 2 * pad, 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [titleText, const SizedBox(height: 3), subtitleText],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A faint pulse line on the Health card. Purely decorative: it never shows or implies a measurement.
class _SoftWave extends StatelessWidget {
  const _SoftWave();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Opacity(
        opacity: 0.45,
        child: CustomPaint(
          size: Size(110, 30),
          painter: _SoftWavePainter(),
        ),
      ),
    );
  }
}

class _SoftWavePainter extends CustomPainter {
  const _SoftWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.2, h * 0.55)
      ..lineTo(w * 0.27, h * 0.2)
      ..lineTo(w * 0.35, h * 0.95)
      ..lineTo(w * 0.43, h * 0.4)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.72, h * 0.55)
      ..lineTo(w * 0.78, h * 0.3)
      ..lineTo(w * 0.85, h * 0.8)
      ..lineTo(w * 0.9, h * 0.55)
      ..lineTo(w, h * 0.55);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF5F7B22),
    );
  }

  @override
  bool shouldRepaint(covariant _SoftWavePainter oldDelegate) => false;
}

/// Glass tints of the five cards (pistachio and shell family only).
class _HubTint {
  final List<Color> colors;
  const _HubTint(this.colors);

  static const health = _HubTint([Color(0x8CFFFFFF), Color(0x38ECF2CE)]);
  static const history = _HubTint([Color(0xB3FBF8EE), Color(0x42F2E8CC)]);
  static const schedule = _HubTint([Color(0x9ED5E383), Color(0x4DB8CB55)]);
  static const nutrition = _HubTint([Color(0x94E7F0B0), Color(0x2EFFFFFF)]);
  static const exercise = _HubTint([Color(0x80BED26E), Color(0x29FFFFFF)]);
}

class _HubCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  final _HubTint tint;
  const _HubCard(this.title, this.subtitle, this.icon, this.page, this.tint);
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


/// The place of the "today" card while its data is on the way: the same glass, two soft bars, a slow pulse.
class _HubTodaySkeleton extends StatefulWidget {
  const _HubTodaySkeleton();

  @override
  State<_HubTodaySkeleton> createState() => _HubTodaySkeletonState();
}

class _HubTodaySkeletonState extends State<_HubTodaySkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(34);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(h / 2),
          ),
        );
    return Semantics(
      container: true,
      label: 'loading',
      child: SediGlass.blur(
        radius: radius,
        sigma: 16,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Opacity(
            opacity: 0.55 + 0.45 * _pulse.value,
            child: DecoratedBox(
              decoration: SediGlass.card(radius),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(width: 64, height: 64, decoration: SediGlass.lightRing()),
                    const SizedBox(width: 18),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [bar(120, 12), const SizedBox(height: 14), bar(180, 18)],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
