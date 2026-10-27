import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../gate3_interactive/presentation/gate3_assistant_starter_bus.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';
import 'lifestyle_exercise_page.dart';
import 'lifestyle_health_page.dart';
import 'lifestyle_history_page.dart';
import 'lifestyle_nutrition_page.dart';
import 'lifestyle_schedule_page.dart';

/// A3 Lifestyle hub — exactly five primary sections. Old sleep/water/mood UI retired here.
class LifestylePage extends StatelessWidget {
  const LifestylePage({super.key});

  static const Color _canvas = Color(0xFFDCE0C0); // Soft Sage (= A3DestinationSurface.canvas)

  @override
  Widget build(BuildContext context) {
    final l10n = LifestyleL10n(SediLocaleController.instance.languageCode);
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
        l10n.scheduleSubtitle,
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
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final c = cards[i];
            return _LifestyleHubDestinationCard(card: c);
          },
        ),
      ),
    );
  }
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
