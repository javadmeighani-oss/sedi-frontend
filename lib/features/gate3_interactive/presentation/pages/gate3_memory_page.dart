import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/memory/memory_overview.dart';
import '../../../../core/memory/memory_overview_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../gate3_localization.dart';
import '../gate3_memory_l10n.dart';
import '../widgets/a3_destination_surface.dart';
import '../widgets/a3_page_app_bar.dart';

/// "My memory" (R-021 / M1+M6): what Sedi remembers about the user — summary, facts and life timeline —
/// where the user can correct or forget anything. Presentation only: every change is done by the I7 memory API.
class Gate3MemoryPage extends StatefulWidget {
  const Gate3MemoryPage({super.key});

  @override
  State<Gate3MemoryPage> createState() => _Gate3MemoryPageState();
}

class _Gate3MemoryPageState extends State<Gate3MemoryPage> {
  final _service = MemoryOverviewService();
  MemoryOverview? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final res = await _service.fetch();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _data = res.data;
      _failed = !res.ok || res.data == null;
    });
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<String?> _askText(
    Gate3Localization l10n, {
    required String title,
    String initial = '',
    String? hint,
  }) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(title),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(hintText: hint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.memoryCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                child: Text(l10n.memorySave),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Gate3Localization l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            content: Text(l10n.memoryDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.memoryCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.memoryDelete),
              ),
            ],
          ),
        );
      },
    );
    return ok == true;
  }

  Future<void> _editFact(Gate3Localization l10n, MemoryFact f) async {
    final v = await _askText(
      l10n,
      title: l10n.memoryFactLabel(f.key),
      initial: f.value,
    );
    if (v == null || v.isEmpty || v == f.value) return;
    final r = await _service.editFact(f.id, v);
    if (!mounted) return;
    if (!r.ok) _toast(l10n.memoryActionFailed);
    await _load();
  }

  Future<void> _deleteFact(Gate3Localization l10n, MemoryFact f) async {
    if (!await _confirmDelete(l10n)) return;
    final r = await _service.deleteFact(f.id);
    if (!mounted) return;
    if (!r.ok) _toast(l10n.memoryActionFailed);
    await _load();
  }

  Future<void> _addEvent(Gate3Localization l10n) async {
    final v = await _askText(
      l10n,
      title: l10n.memoryAddEvent,
      hint: l10n.memoryEventHint,
    );
    if (v == null || v.isEmpty) return;
    final r = await _service.addEvent(v);
    if (!mounted) return;
    if (!r.ok) _toast(l10n.memoryActionFailed);
    await _load();
  }

  Future<void> _editEvent(Gate3Localization l10n, MemoryTimelineEvent e) async {
    final v = await _askText(l10n, title: l10n.memoryEdit, initial: e.title);
    if (v == null || v.isEmpty || v == e.title) return;
    final r = await _service.editEvent(e.id, v);
    if (!mounted) return;
    if (!r.ok) _toast(l10n.memoryActionFailed);
    await _load();
  }

  Future<void> _deleteEvent(Gate3Localization l10n, MemoryTimelineEvent e) async {
    if (!await _confirmDelete(l10n)) return;
    final r = await _service.deleteEvent(e.id);
    if (!mounted) return;
    if (!r.ok) _toast(l10n.memoryActionFailed);
    await _load();
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _row({
    required String title,
    String? subtitle,
    VoidCallback? onEdit,
    required VoidCallback onDelete,
    required Gate3Localization l10n,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: l10n.memoryEdit,
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          IconButton(
            tooltip: l10n.memoryDelete,
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Gate3Localization(SediLocaleController.instance.languageCode);
    final data = _data;
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.memoryOpen),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.gate2ButtonOlive,
                ),
              )
            : RefreshIndicator(
                color: AppTheme.gate2ButtonOlive,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    A3DestinationCard(
                      child: Text(
                        l10n.memoryPageIntro,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_failed || data == null)
                      A3DestinationCard(
                        child: Text(
                          l10n.memoryLoadFailed,
                          style: const TextStyle(color: AppTheme.dangerRed),
                        ),
                      )
                    else if (!data.consent)
                      A3DestinationCard(child: Text(l10n.memoryConsentOff))
                    else ...[
                      if (data.summary.trim().isNotEmpty) ...[
                        A3DestinationCard(
                          child: Text(
                            data.summary,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      A3DestinationCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(l10n.memoryFactsSection),
                            if (data.facts.isEmpty)
                              Text(
                                l10n.memoryEmpty,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            for (final f in data.facts)
                              _row(
                                l10n: l10n,
                                title: f.value,
                                subtitle: l10n.memoryFactLabel(f.key),
                                onEdit: f.editable
                                    ? () => _editFact(l10n, f)
                                    : null,
                                onDelete: () => _deleteFact(l10n, f),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      A3DestinationCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(l10n.memoryTimelineSection),
                            if (data.timeline.isEmpty)
                              Text(
                                l10n.memoryEmpty,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            for (final e in data.timeline)
                              _row(
                                l10n: l10n,
                                title: e.title,
                                subtitle: e.dateLabel,
                                onEdit: () => _editEvent(l10n, e),
                                onDelete: () => _deleteEvent(l10n, e),
                              ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: () => _addEvent(l10n),
                                icon: const Icon(Icons.add_rounded),
                                label: Text(l10n.memoryAddEvent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
