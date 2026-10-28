import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/lifestyle/memory_explorer_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';
import '../widgets/memory_text_sheet.dart';

/// One day of Sedi's memory (H1). Inside the 30-day window the chat text is readable and the user can correct or
/// delete it; older days show only what Sedi derived (summary, events, facts) and the user's corrections sit BESIDE the
/// derived summary - it is never rewritten.
class MemoryDayPage extends StatefulWidget {
  final String iso;

  const MemoryDayPage({super.key, required this.iso});

  @override
  State<MemoryDayPage> createState() => _MemoryDayPageState();
}

class _MemoryDayPageState extends State<MemoryDayPage> {
  final _service = MemoryExplorerService();
  MemoryDayDto? _day;
  bool _loading = true;
  bool _failed = false;
  bool _changed = false;

  LifestyleL10n get _l10n => LifestyleL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _service.day(widget.iso);
    if (!mounted) return;
    setState(() {
      _day = res.ok ? res.data : null;
      _failed = !res.ok || res.data == null;
      _loading = false;
    });
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    final res = await action();
    if (!mounted) return;
    if (res.ok == true) {
      _changed = true;
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.saveFailed)));
    }
  }

  Future<String?> _askText({
    required String title,
    String initial = '',
    required String hint,
    int maxLength = 240,
    int maxLines = 4,
  }) {
    return showMemoryTextSheet(
      context,
      l10n: _l10n,
      title: title,
      initial: initial,
      hint: hint,
      maxLength: maxLength,
      maxLines: maxLines,
    );
  }

  Future<bool> _confirm(String question) async {
    final l10n = _l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          content: Text(question),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteItem)),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _addNote({required bool correction}) async {
    final l10n = _l10n;
    final text = await _askText(
      title: correction ? l10n.fixSummary : l10n.noteForDay,
      hint: correction ? l10n.correctionHint : l10n.noteHint,
    );
    if (text == null) return;
    await _run(() => _service.addNote(
          day: widget.iso,
          text: text,
          kind: correction ? 'correction' : 'note',
        ));
  }

  Future<void> _editTurn(MemoryTurnDto t) async {
    final text = await _askText(
      title: _l10n.editMessageTitle,
      initial: t.userMessage,
      hint: _l10n.editMessageTitle,
      maxLength: 4000,
      maxLines: 8,
    );
    if (text == null || text == t.userMessage) return;
    await _run(() => _service.editTurn(t.id, userMessage: text));
  }

  Future<void> _deleteTurn(MemoryTurnDto t) async {
    if (await _confirm(_l10n.deleteMessageQuestion)) await _run(() => _service.deleteTurn(t.id));
  }

  Future<void> _editNote(MemoryNoteDto n) async {
    final text = await _askText(
      title: n.isCorrection ? _l10n.correctionLabel : _l10n.noteLabel,
      initial: n.text,
      hint: n.isCorrection ? _l10n.correctionHint : _l10n.noteHint,
    );
    if (text == null || text == n.text) return;
    await _run(() => _service.editNote(n.id, text));
  }

  Future<void> _deleteNote(MemoryNoteDto n) async {
    if (await _confirm(_l10n.deleteItemQuestion)) await _run(() => _service.deleteNote(n.id));
  }

  Future<void> _editFact(MemoryFactDto f) async {
    final text = await _askText(
      title: _l10n.learnedThatDay,
      initial: f.value,
      hint: _l10n.learnedThatDay,
      maxLength: 400,
    );
    if (text == null || text == f.value) return;
    await _run(() => _service.editFact(f.id, text));
  }

  Future<void> _deleteFact(MemoryFactDto f) async {
    if (await _confirm(_l10n.deleteItemQuestion)) await _run(() => _service.deleteFact(f.id));
  }

  Future<void> _deleteEvent(MemoryEventDto e) async {
    if (await _confirm(_l10n.deleteItemQuestion)) await _run(() => _service.deleteEvent(e.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final day = _day;
    final dateLabel = CalendarDateMath.formatIsoForProfileDisplay(widget.iso, l10n.lang);
    final wd = CalendarDateMath.weekdayFromIso(widget.iso);
    final sub = day == null
        ? ''
        : CalendarDateMath.localizeDigitsForLanguage(
            '${wd == null ? '' : l10n.weekdayShort(wd)} · ${l10n.daysAgoLabel(day.daysAgo)}',
            l10n.lang,
          );
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) Navigator.pop(context, _changed);
        },
        child: Scaffold(
          backgroundColor: A3DestinationSurface.canvas,
          appBar: A3PageAppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dateLabel),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              ],
            ),
            backgroundColor: A3DestinationSurface.canvas,
          ),
          body: _body(l10n, day),
        ),
      ),
    );
  }

  Widget _body(LifestyleL10n l10n, MemoryDayDto? day) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gate2ButtonOlive));
    }
    if (day == null || _failed) {
      return Center(child: Text(l10n.memoryLoadFailed, style: const TextStyle(color: AppTheme.dangerRed)));
    }
    if (!day.consent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.memoryConsentOff, textAlign: TextAlign.center),
        ),
      );
    }
    final old = !day.rawVisible;
    final empty = day.turns.isEmpty &&
        day.summaryText.isEmpty &&
        day.events.isEmpty &&
        day.notes.isEmpty &&
        day.facts.isEmpty;
    return RefreshIndicator(
      color: AppTheme.gate2ButtonOlive,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (old) _banner(l10n),
          if (day.turns.isNotEmpty) ...[
            _heading(l10n.dayConversations),
            _turnsCard(l10n, day.turns),
          ],
          if (day.summaryText.isNotEmpty || !day.chips.isEmpty) ...[
            _heading(l10n.sediDaySummary),
            _summaryCard(l10n, day),
          ],
          if (old && day.summaryText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _addNote(correction: true),
                child: Text(l10n.fixSummary),
              ),
            ),
          _notesAndEvents(l10n, day, old),
          if (day.facts.isNotEmpty) ...[
            _heading(l10n.learnedThatDay),
            for (final f in day.facts) _factRow(l10n, f),
          ],
          if (empty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(l10n.emptyDay,
                  textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _heading(String text, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _banner(LifestyleL10n l10n) => A3DestinationCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 22, color: AppTheme.gate2ButtonOlive),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n.oldDayBanner,
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textPrimary)),
            ),
          ],
        ),
      );

  Widget _iconAction(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) => IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: Icon(icon, size: 20, color: color ?? AppTheme.gate2ButtonOlive),
        onPressed: onTap,
      );

  Widget _turnsCard(LifestyleL10n l10n, List<MemoryTurnDto> turns) {
    return A3DestinationCard(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Column(
        children: [
          for (var i = 0; i < turns.length; i++) ...[
            if (i > 0) const Divider(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          CalendarDateMath.localizeDigitsForLanguage(
                              '${turns[i].time} · ${l10n.youLabel}', l10n.lang),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary),
                        ),
                      ),
                      Text(turns[i].userMessage,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      if ((turns[i].sediResponse ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(l10n.sediLabel,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                        Text(turns[i].sediResponse!,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ],
                    ],
                  ),
                ),
                _iconAction(Icons.edit_outlined, l10n.editItem, () => _editTurn(turns[i])),
                _iconAction(Icons.delete_outline_rounded, l10n.deleteItem, () => _deleteTurn(turns[i]),
                    color: AppTheme.dangerRed),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(LifestyleL10n l10n, MemoryDayDto day) {
    final chips = <String>[
      ...day.chips.topics,
      if (day.chips.hrAvg > 0) l10n.hrAvgChip(day.chips.hrAvg),
      if (day.chips.userDone > 0)
        CalendarDateMath.localizeDigitsForLanguage(
            l10n.lang == 'en' ? '${day.chips.userDone} done' : '${day.chips.userDone} ✓', l10n.lang),
    ];
    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (day.summaryText.isNotEmpty)
            Text(day.summaryText,
                style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in chips) A3DestinationChip(label: c, selected: false, onTap: () {})],
            ),
          ],
        ],
      ),
    );
  }

  Widget _notesAndEvents(LifestyleL10n l10n, MemoryDayDto day, bool old) {
    final hasAny = day.events.isNotEmpty || day.notes.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          old && day.notes.isNotEmpty ? l10n.correctionsTitle : l10n.eventsAndNotes,
          trailing: TextButton(
            onPressed: () => _addNote(correction: false),
            child: Text(l10n.addItem),
          ),
        ),
        for (final e in day.events)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: A3DestinationCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        if (e.timeLabel.isNotEmpty)
                          Text(
                              CalendarDateMath.localizeDigitsForLanguage(e.timeLabel, l10n.lang),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (e.lifeEvent)
                    _iconAction(Icons.delete_outline_rounded, l10n.deleteItem, () => _deleteEvent(e),
                        color: AppTheme.dangerRed),
                ],
              ),
            ),
          ),
        for (final n in day.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: A3DestinationCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.isCorrection ? l10n.correctionLabel : l10n.noteLabel,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                        Text(n.text,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  _iconAction(Icons.edit_outlined, l10n.editItem, () => _editNote(n)),
                  _iconAction(Icons.delete_outline_rounded, l10n.deleteItem, () => _deleteNote(n),
                      color: AppTheme.dangerRed),
                ],
              ),
            ),
          ),
        if (old && day.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Text(l10n.correctionExplain,
                style: const TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textSecondary)),
          ),
        if (!hasAny) const SizedBox(height: 0),
      ],
    );
  }

  Widget _factRow(LifestyleL10n l10n, MemoryFactDto f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: A3DestinationCard(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(f.value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            if (f.editable) _iconAction(Icons.edit_outlined, l10n.editItem, () => _editFact(f)),
            _iconAction(Icons.delete_outline_rounded, l10n.deleteItem, () => _deleteFact(f),
                color: AppTheme.dangerRed),
          ],
        ),
      ),
    );
  }
}
