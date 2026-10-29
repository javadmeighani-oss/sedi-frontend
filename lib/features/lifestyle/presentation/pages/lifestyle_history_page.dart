import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../data/dto/history_response.dart';
import '../../../../services/lifestyle/memory_explorer_service.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
import '../lifestyle_l10n.dart';
import '../widgets/history_calendar_card.dart';
import 'memory_day_page.dart';
import 'memory_search_page.dart';

/// Backend [HistoryResponse.currentGroupKey] is the only current-day authority.
/// Null means fail-closed: do not reconstruct a device day.
List<HistoryGroupItem>? archiveDaysFromHistory(HistoryResponse? history) {
  final today = history?.currentGroupKey;
  if (today == null || today.isEmpty) return null;
  return history!.items.where((g) => g.key != today).toList(growable: false);
}

/// Trim is emptiness-only. Display the original stored copy unchanged.
String? exactStoredTranscriptText(String? stored) {
  if (stored == null || stored.trim().isEmpty) return null;
  return stored;
}

/// My History (H1; pilot V1 redesign R-034): search Sedi's memory, see the LAST day, jump to any day on a compact
/// calendar, read and correct the last 30 days of chat, and see what Sedi kept about older days. The note / correction
/// box lives only inside a day that was opened. Every date comes from the backend; the page never reads the device clock.
class LifestyleHistoryPage extends StatefulWidget {
  const LifestyleHistoryPage({super.key});

  @override
  State<LifestyleHistoryPage> createState() => _LifestyleHistoryPageState();
}

class _LifestyleHistoryPageState extends State<LifestyleHistoryPage> {
  final _api = ApiClient();
  final _memory = MemoryExplorerService();
  final _searchController = TextEditingController();
  HistoryResponse? _history;
  bool _loading = true;
  String? _error;
  String? _selectedIso;
  Set<String> _memoryDays = const {};
  String? _dotsFrom;
  String? _dotsTo;

  LifestyleL10n get _l10n =>
      LifestyleL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _history = null;
    });
    await _loadHistory();
    if (!mounted) return;
    setState(() => _loading = false);
    if (_dotsFrom != null && _dotsTo != null) _loadDots(_dotsFrom!, _dotsTo!);
  }

  Future<void> _loadHistory() async {
    try {
      final histRes = await _api.getRaw(
        '/memory/history',
        queryParams: {
          'group': 'daily',
          'limit': '31',
          'offset': '0',
        },
      );
      HistoryResponse? hist;
      if (histRes.ok && histRes.data != null) {
        hist = HistoryResponse.tryParse(histRes.data);
      }
      if (!mounted) return;
      setState(() {
        _history = hist;
        if (hist == null && histRes.errorMessage.isNotEmpty) {
          _error = histRes.errorMessage;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadDots(String from, String to) async {
    _dotsFrom = from;
    _dotsTo = to;
    try {
      final days = await _memory.daysWithMemory(from: from, to: to);
      if (!mounted || _dotsFrom != from) return;
      setState(() => _memoryDays = days);
    } catch (_) {
      // dots are decoration: the calendar still works without them
    }
  }

  String? get _todayIso {
    final key = _history?.currentGroupKey;
    return (key == null || key.isEmpty) ? null : key;
  }

  Future<void> _openDay(String iso) async {
    setState(() => _selectedIso = iso);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => MemoryDayPage(iso: iso)),
    );
    if (changed == true && mounted) _load();
  }

  /// Searches Sedi's whole memory (the last 30 days of chat, summaries, events and learned facts).
  void _openSearch(String query) {
    final q = query.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_l10n.searchMemoryHint)));
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemorySearchPage(initialQuery: q, todayIso: _todayIso ?? ''),
      ),
    );
  }

  String _formatDayLabel(String key, LifestyleL10n l10n) {
    final formatted = CalendarDateMath.formatIsoForProfileDisplay(key, l10n.lang);
    final dt = CalendarDateMath.parseIsoLocalDate(key);
    if (dt == null) return formatted;
    final weekday = l10n.weekdayShort(dt.weekday);
    if (weekday.isEmpty) return formatted;
    final sep = l10n.lang == 'en' ? ', ' : '، ';
    return '$weekday$sep$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final today = _todayIso;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
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
                l10n.myHistory,
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
            RefreshIndicator(
              color: AppTheme.gate2ButtonOlive,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, top, 16, 24),
                children: [
                  _searchBox(l10n),
                  const SizedBox(height: 8),
                  // the 30-day rule as one icon + one short line
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: Color(0xFF5B6640)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.historyExplain,
                            style: const TextStyle(
                              color: Color(0xFF5B6640),
                              height: 1.5,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ONE last day, ABOVE the calendar
                  if (!_loading) ..._lastDayCard(l10n),
                  if (today != null) ...[
                    const SizedBox(height: 4),
                    HistoryCalendarCard(
                      todayIso: today,
                      selectedIso: _selectedIso,
                      memoryDays: _memoryDays,
                      l10n: l10n,
                      onPick: _openDay,
                      onMonthChanged: _loadDots,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A real input: Enter on the keyboard and the round search button both open the search.
  Widget _searchBox(LifestyleL10n l10n) {
    final radius = BorderRadius.circular(26);
    return SediGlass.blur(
      radius: radius,
      sigma: 16,
      child: Container(
        height: 52,
        padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 7, 0),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.62),
              Colors.white.withOpacity(0.22),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.85)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF48551F).withOpacity(0.13),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _openSearch,
                cursorColor: SediGlass.ink,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l10n.searchMemoryHint,
                  hintStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5B6640),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: l10n.searchMemoryHint,
              child: GestureDetector(
                onTap: () => _openSearch(_searchController.text),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: SediGlass.pistachioSphere(),
                  child: const Icon(Icons.search_rounded,
                      size: 21, color: SediGlass.inkDeep),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The most recent PAST day with conversations (not seven) as one glass row; errors stay visible.
  List<Widget> _lastDayCard(LifestyleL10n l10n) {
    if (_error != null && _history == null) {
      return [
        A3DestinationCard(
          child: Text(
            _error!,
            style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
      ];
    }

    final past = archiveDaysFromHistory(_history);
    if (past == null) {
      return [
        Text(
          l10n.archiveTemporarilyUnavailable,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
      ];
    }
    if (past.isEmpty) {
      return [
        Text(
          l10n.noConversations,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
      ];
    }

    final group = past.first;
    final count = CalendarDateMath.localizeDigitsForLanguage(
      l10n.turnCount(group.turns
          .where((t) => exactStoredTranscriptText(t.userMessage) != null)
          .length),
      l10n.lang,
    );
    final radius = BorderRadius.circular(26);
    return [
      SediGlass.blur(
        radius: radius,
        sigma: 14,
        child: DecoratedBox(
          decoration: SediGlass.card(radius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => _openDay(group.key),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: SediGlass.tile().copyWith(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.history_rounded,
                          size: 23, color: SediGlass.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDayLabel(group.key, l10n),
                            style: const TextStyle(
                              color: Color(0xFF1F2A09),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            count,
                            style: const TextStyle(
                              color: Color(0xFF4B5530),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      l10n.isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: SediGlass.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }
}
