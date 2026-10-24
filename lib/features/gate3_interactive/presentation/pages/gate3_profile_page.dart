import 'package:flutter/material.dart';

import '../../../../core/auth/auth_helper.dart';
import '../../../../core/auth/auth_otp_service.dart';
import '../../../../core/auth/auth_profile_service.dart';
import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/dto/auth/me_profile.dart';
import '../../../auth_otp/presentation/a2_phone_e164.dart';
import '../../../auth_otp/presentation/gate2_otp_input.dart';
import '../gate3_localization.dart';
import '../widgets/a3_destination_surface.dart';
import '../widgets/a3_page_app_bar.dart';
import '../widgets/gate3_profile_memory_control.dart';

/// A3 Profile — user info, user summary, Memory & Privacy, Log out.
class Gate3ProfilePage extends StatefulWidget {
  const Gate3ProfilePage({super.key});

  @override
  State<Gate3ProfilePage> createState() => _Gate3ProfilePageState();
}

class _Gate3ProfilePageState extends State<Gate3ProfilePage> {
  final _profile = AuthProfileService();
  final _otp = AuthOtpService();
  final _api = ApiClient();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _otpFocus = FocusNode();

  MeProfileDto? _me;
  String _canonicalSummary = '';
  bool _loading = true;
  String? _error;
  String? _phoneFlowError;
  String? _phoneFlowSuccess;
  bool _changingPhone = false;
  bool _otpSent = false;
  bool _phoneBusy = false;
  String? _pendingNewPhone;
  A2CountryDialCode _dial = A2PhoneE164.defaultDialCode;

  Gate3Localization get _l10n =>
      Gate3Localization(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final meRes = await _profile.fetchMe(recoverSessionOn401: true);
    final summaryRes = await _api.get<String>(
      '/auth/me/profile-summary',
      parser: canonicalProfileSummaryText,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!meRes.ok || meRes.data == null) {
        _error = meRes.errorMessage;
      } else {
        _me = meRes.data;
        final lang = meRes.data!.preferredLanguage;
        if (lang != null && lang.isNotEmpty) {
          SediLocaleController.instance.reconcileFromBackendConfirmed(lang);
        }
      }
      if (summaryRes.ok && summaryRes.data != null) {
        _canonicalSummary = summaryRes.data!;
      } else {
        _canonicalSummary = '';
      }
    });
  }

  String _mapPhoneError(String? code, String? message) {
    final l10n = _l10n;
    switch ((code ?? '').toUpperCase()) {
      case 'PHONE_INVALID':
        return l10n.phoneInvalid;
      case 'PHONE_SAME':
        return l10n.phoneSame;
      case 'PHONE_DUPLICATE':
        return l10n.phoneDuplicate;
      case 'OTP_INVALID':
        return l10n.phoneOtpInvalid;
      case 'OTP_EXPIRED':
        return l10n.phoneOtpExpired;
      case 'OTP_RATE_LIMITED':
      case 'TOO_MANY_ATTEMPTS':
        return l10n.phoneOtpRateLimited;
      default:
        if (message != null && message.trim().isNotEmpty) return message;
        return l10n.phoneChangeNetworkError;
    }
  }

  Future<void> _requestPhoneOtp() async {
    final l10n = _l10n;
    final e164 = A2PhoneE164.normalize(
      nationalInput: _phoneCtrl.text,
      dialCode: _dial,
    );
    if (!A2PhoneE164.isValid(
      nationalInput: _phoneCtrl.text,
      dialCode: _dial,
    )) {
      setState(() => _phoneFlowError = l10n.phoneInvalid);
      return;
    }
    final current = (_me?.phone ?? '').trim();
    if (current.isNotEmpty && current == e164) {
      setState(() => _phoneFlowError = l10n.phoneSame);
      return;
    }

    setState(() {
      _phoneBusy = true;
      _phoneFlowError = null;
      _phoneFlowSuccess = null;
    });
    final lang = SediLocaleController.instance.languageCode;
    final res = await _otp.requestPhoneChangeOtp(newPhone: e164, language: lang);
    if (!mounted) return;
    setState(() {
      _phoneBusy = false;
      if (!res.ok) {
        _phoneFlowError = _mapPhoneError(res.error?.code, res.errorMessage);
        _otpSent = false;
        _pendingNewPhone = null;
      } else {
        _otpSent = true;
        _pendingNewPhone = e164;
        _otpCtrl.clear();
      }
    });
  }

  Future<void> _verifyPhoneOtp() async {
    final pending = _pendingNewPhone;
    if (pending == null || pending.isEmpty) return;
    final code = _otpCtrl.text.trim();
    setState(() {
      _phoneBusy = true;
      _phoneFlowError = null;
      _phoneFlowSuccess = null;
    });
    final res = await _otp.verifyPhoneChangeOtp(newPhone: pending, code: code);
    if (!mounted) return;
    if (!res.ok || res.data == null) {
      setState(() {
        _phoneBusy = false;
        _phoneFlowError = _mapPhoneError(res.error?.code, res.errorMessage);
      });
      return;
    }
    final meRes = await _profile.fetchMe(recoverSessionOn401: true);
    if (!mounted) return;
    setState(() {
      _phoneBusy = false;
      if (meRes.ok && meRes.data != null) {
        _me = meRes.data;
      } else {
        _me = res.data;
      }
      _changingPhone = false;
      _otpSent = false;
      _pendingNewPhone = null;
      _phoneCtrl.clear();
      _otpCtrl.clear();
      _phoneFlowSuccess = _l10n.phoneChangeSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final textDir =
        l10n.isRtl ? TextDirection.rtl : TextDirection.ltr;
    return Directionality(
      textDirection: textDir,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.profileTitle),
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
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: A3DestinationCard(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.dangerRed),
                          ),
                        ),
                      ),
                    A3DestinationCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.userInformationSection,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          A3DestinationFact(
                            label: l10n.profileNameLabel,
                            value: _me?.name ?? '—',
                          ),
                          A3DestinationFact(
                            label: l10n.profileDobLabel,
                            value: _formatDob(_me),
                          ),
                          A3DestinationFact(
                            label: l10n.profileSexLabel,
                            value: l10n.profileSexValue(_me?.sex),
                          ),
                          A3DestinationFact(
                            label: l10n.profileLanguageLabel,
                            value: _formatLanguage(_me?.preferredLanguage),
                          ),
                          _phoneCard(l10n),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(l10n),
                    const SizedBox(height: 16),
                    const Gate3ProfileMemoryControl(),
                    const SizedBox(height: 16),
                    A3DestinationCard(
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              AuthHelper.performLogout(context: context),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.logoutApp),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                              color: AppTheme.gate2BorderSubtle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _phoneCard(Gate3Localization l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        A3DestinationFact(
          label: l10n.profilePhoneLabel,
          value: _me?.phone ?? '—',
          valueDirection: TextDirection.ltr,
        ),
        if (!_changingPhone) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppTheme.gate2ButtonOlive,
              ),
              onPressed: () => setState(() {
                _changingPhone = true;
                _phoneFlowError = null;
                _phoneFlowSuccess = null;
                _otpSent = false;
              }),
              child: Text(l10n.changePhone),
            ),
          ),
          if (_phoneFlowSuccess != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _phoneFlowSuccess!,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        if (_changingPhone) ..._phoneChangeWidgets(l10n),
      ],
    );
  }

  List<Widget> _phoneChangeWidgets(Gate3Localization l10n) {
    return [
      const SizedBox(height: 6),
      Text(
        l10n.newPhoneLabel,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          DropdownButton<A2CountryDialCode>(
            value: _dial,
            items: A2PhoneE164.dialCodes
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayDial),
                  ),
                )
                .toList(),
            onChanged: _phoneBusy
                ? null
                : (v) {
                    if (v != null) setState(() => _dial = v);
                  },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              enabled: !_phoneBusy && !_otpSent,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      if (_otpSent) ...[
        const SizedBox(height: 10),
        Text(
          l10n.otpCodeLabel,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Gate2OtpInput(
          controller: _otpCtrl,
          focusNode: _otpFocus,
          enabled: !_phoneBusy,
        ),
      ],
      if (_phoneFlowError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _phoneFlowError!,
            style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
          ),
        ),
      if (_phoneFlowSuccess != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _phoneFlowSuccess!,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          if (!_otpSent)
            ElevatedButton(
              onPressed: _phoneBusy ? null : _requestPhoneOtp,
              child: _phoneBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.sendPhoneOtp),
            )
          else
            ElevatedButton(
              onPressed: _phoneBusy ? null : _verifyPhoneOtp,
              child: _phoneBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.verifyPhoneOtp),
            ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _phoneBusy
                ? null
                : () => setState(() {
                      _changingPhone = false;
                      _otpSent = false;
                      _pendingNewPhone = null;
                      _phoneFlowError = null;
                    }),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    ];
  }

  String _formatDob(MeProfileDto? me) {
    if (me == null) return '—';
    final lang = SediLocaleController.instance.languageCode;
    if (me.dateOfBirth != null && me.dateOfBirth!.isNotEmpty) {
      return CalendarDateMath.formatIsoForProfileDisplay(
        me.dateOfBirth!,
        lang,
      );
    }
    if (me.birthYear != null && me.birthMonth != null && me.birthDay != null) {
      final iso =
          '${me.birthYear!.toString().padLeft(4, '0')}-'
          '${me.birthMonth!.toString().padLeft(2, '0')}-'
          '${me.birthDay!.toString().padLeft(2, '0')}';
      return CalendarDateMath.formatIsoForProfileDisplay(iso, lang);
    }
    return '—';
  }

  String _formatLanguage(String? code) {
    switch ((code ?? '').toLowerCase()) {
      case 'fa':
        return 'فارسی';
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return '—';
    }
  }

  Widget _buildSummaryCard(Gate3Localization l10n) {
    final text = _canonicalSummary.trim();
    final formatted = text.isEmpty ? '' : formatMemoryFacts(text, l10n);
    final body = formatted.isEmpty ? l10n.userSummaryEmpty : formatted;
    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.userSummarySection,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Canonical user-facing summary from `/auth/me/profile-summary` data.
///
/// Contract: `{rows:[{key,status}], facts:[{key,value}]}`. `rows` are capability
/// and plan-status codes (never shown as prose). `facts` is what Sedi remembers
/// about the user (its second memory); each becomes one `key<TAB>value` line that
/// [formatMemoryFacts] localizes. An empty result shows only the localized empty state.
final String _factSep = String.fromCharCode(9);
final String _factNl = String.fromCharCode(10);

String canonicalProfileSummaryText(Object? data) {
  if (data is! Map) return '';
  final facts = data['facts'];
  if (facts is! List) return '';
  final lines = <String>[];
  for (final f in facts) {
    if (f is! Map) continue;
    final key = f['key'];
    final value = f['value'];
    if (key is String &&
        key.isNotEmpty &&
        value is String &&
        value.trim().isNotEmpty) {
      lines.add('$key$_factSep${value.trim().replaceAll(_factNl, ' ')}');
    }
  }
  return lines.join(_factNl);
}

/// Renders [canonicalProfileSummaryText] output as localized "label: value" lines.
String formatMemoryFacts(String encoded, Gate3Localization l10n) {
  final out = <String>[];
  for (final line in encoded.split(_factNl)) {
    final sep = line.indexOf(_factSep);
    if (sep <= 0) continue;
    final label = l10n.memoryFactLabel(line.substring(0, sep));
    final value = line.substring(sep + 1).trim();
    if (label.isEmpty || value.isEmpty) continue;
    out.add('• $label: $value');
  }
  return out.join(_factNl);
}
