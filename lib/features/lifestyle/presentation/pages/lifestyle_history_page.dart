import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/dto/history_response.dart';
import '../../../../services/lifestyle/memory_explorer_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';
import '../widgets/history_calendar_card.dart';
import '../widgets/memory_text_sheet.dart';
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

/// My History (H1): search Sedi's memory, jump to any day on a calendar, read and correct the last 30 days of chat,
/// and see what Sedi kept about older days. Every date comes from the backend; the page never reads the device clock.
class LifestyleHistoryPage extends StatefulWidget {
  const LifestyleHistoryPage({super.key});

  @override
  State<LifestyleHistoryPage> createState() => _LifestyleHistoryPageState();
}

class _LifestyleHistoryPageState extends State<LifestyleHistoryPage> {
  final _api = ApiClient();
  final _memory = MemoryExplorerService();
  final _searchController = TextEditingController();
  String _group = 'daily';
  HistoryResponse? _history;
  String? _summaryText;
  bool _loading = true;
  bool _summaryLoading = false;
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
      _summaryText = null;
    });
    await Future.wait([_loadHistory(), _loadSummary()]);
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

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final summaryType = _group.toUpperCase();
      final sumRes = await _api.getRaw(
        '/memory/period-summary',
        queryParams: {'summary_type': summaryType},
      );
      String? narrative;
      if (sumRes.ok && sumRes.data != null) {
        narrative = sumRes.data!['narrative_summary']?.toString();
      }
      if (!mounted) return;
      setState(() {
        _summaryText = narrative;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
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

  void _openSearch(String query) {
    final q = query.trim();
    if (q.length < 2) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemorySearchPage(initialQuery: q, todayIso: _todayIso ?? ''),
      ),
    );
  }

  Future<void> _addNote() async {
    final l10n = _l10n;
    final day = _selectedIso ?? _todayIso;
    if (day == null) return;
    final text = await showMemoryTextSheet(
      context,
      l10n: l10n,
      title: l10n.noteForDay,
      hint: l10n.noteHint,
    );
    if (text == null) return;
    final res = await _memory.addNote(day: day, text: text);
    if (!mounted) return;
    if (res.ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
    }
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
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.myHistory),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppTheme.ctaFill,
                foregroundColor: AppTheme.textPrimary,
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              onPressed: today == null ? null : _addNote,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.noteForDay),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppTheme.gate2ButtonOlive,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _openSearch,
                decoration: InputDecoration(
                  hintText: l10n.searchMemoryHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.historyExplain,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (today != null)
                HistoryCalendarCard(
                  todayIso: today,
                  selectedIso: _selectedIso,
                  memoryDays: _memoryDays,
                  l10n: l10n,
                  onPick: _openDay,
                  onMonthChanged: _loadDots,
                ),
              if (today != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.gate2ButtonOlive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.memoryDotLegend,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                l10n.recentDays,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (!_loading) ..._recentDayCards(l10n),
              const SizedBox(height: 14),
              A3DestinationCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sediSummaries,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('daily', l10n.daily),
                        _chip('weekly', l10n.weekly),
                        _chip('monthly', l10n.monthly),
                        _chip('yearly', l10n.yearly),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading || _summaryLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(
                            color: AppTheme.gate2ButtonOlive,
                          ),
                        ),
                      )
                    else
                      Text(
                        (_summaryText != null && _summaryText!.trim().isNotEmpty)
                            ? _summaryText!
                            : l10n.noSummary,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _recentDayCards(LifestyleL10n l10n) {
    if (_error != null && _history == null) {
      return [
        Text(
          _error!,
          style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
        ),
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
      ];
    }
    final todayKey = _todayIso;
    final todayGroup = _history!.items.where((g) => g.key == todayKey).toList();
    final days = [...todayGroup, ...past].take(7).toList(growable: false);
    if (days.isEmpty) {
      return [
        Text(
          l10n.noConversations,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ];
    }

    return [
      for (final group in days)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: A3DestinationCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            onTap: () => _openDay(group.key),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.key == todayKey
                            ? '${CalendarDateMath.formatIsoForProfileDisplay(group.key, l10n.lang)} · ${l10n.todayLabel}'
                            : _formatDayLabel(group.key, l10n),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CalendarDateMath.localizeDigitsForLanguage(
                          l10n.turnCount(group.turns
                              .where((t) => exactStoredTranscriptText(t.userMessage) != null)
                              .length),
                          l10n.lang,
                        ),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  l10n.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _chip(String key, String label) {
    return A3DestinationChip(
      label: label,
      selected: _group == key,
      onTap: () {
        if (_group == key) return;
        setState(() => _group = key);
        _loadSummary();
      },
    );
  }
}
