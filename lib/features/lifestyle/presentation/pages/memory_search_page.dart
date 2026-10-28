import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/lifestyle/memory_explorer_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../domain/history_calendar.dart';
import '../lifestyle_l10n.dart';
import 'memory_day_page.dart';

/// Keyword search over Sedi's memory (H1). The backend searches raw chat only inside the 30-day window; older days are
/// searched through derived summaries, events, notes and facts.
class MemorySearchPage extends StatefulWidget {
  final String initialQuery;

  /// The backend's current day: the only anchor for the "3 months / 1 month" ranges (no device clock).
  final String todayIso;

  const MemorySearchPage({super.key, required this.initialQuery, required this.todayIso});

  @override
  State<MemorySearchPage> createState() => _MemorySearchPageState();
}

class _MemorySearchPageState extends State<MemorySearchPage> {
  final _service = MemoryExplorerService();
  late final TextEditingController _controller;
  List<MemorySearchHit> _hits = const [];
  bool _loading = false;
  bool _searched = false;
  String _range = 'all';

  LifestyleL10n get _l10n => LifestyleL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 2) _run();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _controller.text.trim();
    if (q.length < 2) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    final from = switch (_range) {
      '3m' => isoMinusDays(widget.todayIso, 92),
      '1m' => isoMinusDays(widget.todayIso, 31),
      _ => null,
    };
    List<MemorySearchHit> hits;
    try {
      hits = await _service.search(q, from: from, to: from == null ? null : widget.todayIso);
    } catch (_) {
      hits = const [];
    }
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loading = false;
    });
  }

  Widget _rangeChip(String key, String label) => A3DestinationChip(
        label: label,
        selected: _range == key,
        onTap: () {
          if (_range == key) return;
          setState(() => _range = key);
          _run();
        },
      );

  List<InlineSpan> _highlight(String text, String query) {
    final lower = text.toLowerCase();
    final needle = query.trim().toLowerCase();
    final i = needle.isEmpty ? -1 : lower.indexOf(needle);
    if (i < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: text.substring(i, i + needle.length),
        style: const TextStyle(
          backgroundColor: AppTheme.pistachioGreen,
          color: Color(0xFF1B2208),
          fontWeight: FontWeight.w700,
        ),
      ),
      TextSpan(text: text.substring(i + needle.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.myHistory),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _run(),
              decoration: InputDecoration(
                hintText: l10n.searchMemoryHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _hits = const [];
                      _searched = false;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _rangeChip('all', l10n.rangeAll),
                _rangeChip('3m', l10n.rangeThreeMonths),
                _rangeChip('1m', l10n.rangeOneMonth),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppTheme.gate2ButtonOlive))
            else if (_searched && _hits.isEmpty)
              Text(l10n.noSearchResults, style: const TextStyle(color: AppTheme.textSecondary))
            else ...[
              if (_searched)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                  child: Text(
                    CalendarDateMath.localizeDigitsForLanguage(
                        l10n.searchResultCount(_hits.length), l10n.lang),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary),
                  ),
                ),
              for (final h in _hits) _hitCard(l10n, h),
            ],
            const SizedBox(height: 12),
            Text(l10n.searchOldDaysNote,
                style: const TextStyle(fontSize: 13, height: 1.7, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _hitCard(LifestyleL10n l10n, MemorySearchHit h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: A3DestinationCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<bool>(builder: (_) => MemoryDayPage(iso: h.date)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    CalendarDateMath.formatIsoForProfileDisplay(h.date, l10n.lang),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.pistachioGreen.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(l10n.hitType(h.type),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 14.5, height: 1.7, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                children: _highlight(h.snippet, _controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
