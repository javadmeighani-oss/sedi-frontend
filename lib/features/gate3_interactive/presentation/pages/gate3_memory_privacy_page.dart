import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/memory/memory_consent_service.dart';
import '../../../../core/memory/memory_consent_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../gate3_localization.dart';
import '../widgets/a3_page_app_bar.dart';

/// Settings → Memory & Privacy. Reuses existing I6 consent endpoints only.
class Gate3MemoryPrivacyPage extends StatefulWidget {
  const Gate3MemoryPrivacyPage({super.key, this.service});

  final MemoryConsentService? service;

  @override
  State<Gate3MemoryPrivacyPage> createState() => _Gate3MemoryPrivacyPageState();
}

class _Gate3MemoryPrivacyPageState extends State<Gate3MemoryPrivacyPage> {
  late final MemoryConsentService _service =
      widget.service ?? MemoryConsentService();

  MemoryConsentStatus? _status;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  Gate3Localization get _l10n =>
      Gate3Localization(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.fetchStatus();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        _status = res.data;
      } else {
        _error = _l10n.memoryConsentLoadError;
      }
    });
  }

  Future<void> _grant() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await _service.grant();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res.ok && res.data != null) {
        _status = res.data;
      } else {
        _error = _l10n.memoryConsentActionError;
      }
    });
  }

  Future<void> _revoke() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await _service.revoke();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res.ok && res.data != null) {
        _status = res.data;
      } else {
        _error = _l10n.memoryConsentActionError;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final textDir = l10n.isRtl ? TextDirection.rtl : TextDirection.ltr;
    return Directionality(
      textDirection: textDir,
      child: Scaffold(
        backgroundColor: AppTheme.gate2WarmBackground,
        appBar: A3PageAppBar(title: Text(l10n.memoryAndPrivacy)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.dangerRed),
                        ),
                      ),
                    Text(
                      l10n.memoryConsentStatusLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.summaryStatusLabel(_status?.status ?? 'unavailable'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.memoryConsentInvitation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_status?.granted == true)
                      OutlinedButton(
                        onPressed: _busy ? null : _revoke,
                        child: Text(
                          _busy
                              ? l10n.memoryConsentBusy
                              : l10n.memoryConsentRevoke,
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: _busy ? null : _grant,
                        child: Text(
                          _busy
                              ? l10n.memoryConsentBusy
                              : l10n.memoryConsentGrant,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
