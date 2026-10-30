import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/auth_helper.dart';
import '../../../../core/auth/auth_otp_service.dart';
import '../../../../core/auth/auth_profile_service.dart';
import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../data/dto/auth/me_profile.dart';
import '../../../auth_otp/presentation/a2_phone_e164.dart';
import '../../../auth_otp/presentation/gate2_otp_input.dart';
import '../../models/gate3_interaction_state.dart';
import '../gate3_localization.dart';
import '../gate3_memory_l10n.dart';
import '../profile_language_change.dart';
import 'gate3_memory_page.dart';
import '../widgets/a3_destination_surface.dart';
import '../widgets/a3_page_app_bar.dart';
import '../widgets/gate3_profile_memory_control.dart';
import '../widgets/sedi_hologram_orb.dart';
import '../widgets/sedi_scene_backdrop.dart';

/// A3 Profile — user info, user summary, Memory & Privacy, Log out.
/// Pilot V1 (R-034/R-035): one glass screen, icons before words, the Sedi sphere beside the title.
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
    final res =
        await _otp.requestPhoneChangeOtp(newPhone: e164, language: lang);
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
    final textDir = l10n.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    return Directionality(
      textDirection: textDir,
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
                l10n.profileTitle,
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
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.gate2ButtonOlive,
                ),
              )
            else
              RefreshIndicator(
                color: AppTheme.gate2ButtonOlive,
                onRefresh: _load,
                child: LayoutBuilder(
                  builder: (context, box) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, top, 16, 20),
                      child: ConstrainedBox(
                        // Everything fits one screen; the scroll only exists for the keyboard and tiny screens.
                        constraints: BoxConstraints(
                          minHeight: (box.maxHeight - top - 20)
                              .clamp(0.0, double.infinity)
                              .toDouble(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: A3DestinationCard(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppTheme.dangerRed,
                                    ),
                                  ),
                                ),
                              ),
                            Semantics(
                              container: true,
                              label: l10n.userInformationSection,
                              child: _glassCard(
                                strong: true,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // The name stands alone: no icon beside it.
                                    Text(
                                      _me?.name ?? '—',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _factTile(
                                          icon: Icons.cake_outlined,
                                          label: l10n.profileDobLabel,
                                          value: _formatDob(_me),
                                          forceLtr: true,
                                        ),
                                        const SizedBox(width: 10),
                                        _factTile(
                                          icon: _sexIcon(_me?.sex),
                                          label: l10n.profileSexLabel,
                                          value: l10n.profileSexValue(_me?.sex),
                                        ),
                                        const SizedBox(width: 10),
                                        _factTile(
                                          icon: Icons.language_rounded,
                                          label: l10n.profileLanguageLabel,
                                          value: _formatLanguage(
                                              _me?.preferredLanguage),
                                          onTap: _chooseLanguage,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _phoneCard(l10n),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryCard(l10n),
                            const SizedBox(height: 12),
                            const Gate3ProfileMemoryControl(),
                            const SizedBox(height: 12),
                            _logoutButton(l10n),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- glass building blocks (pilot V1, R-034) ----

  Widget _glassCard({
    required Widget child,
    required EdgeInsets padding,
    bool strong = false,
  }) {
    final radius = BorderRadius.circular(30);
    return SediGlass.blur(
      radius: radius,
      sigma: 18,
      child: DecoratedBox(
        decoration: SediGlass.card(radius, strong: strong),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _factTile({
    required IconData icon,
    required String label,
    required String value,
    bool forceLtr = false,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
      decoration: SediGlass.tile(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: SediGlass.ink),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  textDirection: forceLtr ? TextDirection.ltr : null,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: SediGlass.ink,
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.expand_more_rounded,
                      size: 18, color: SediGlass.ink),
              ],
            ),
          ),
        ],
      ),
    );
    return Expanded(
      child: Semantics(
        container: true,
        button: onTap != null,
        label: '$label: $value',
        excludeSemantics: true,
        onTap: onTap,
        child: onTap == null
            ? tile
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: tile,
              ),
      ),
    );
  }

  Future<void> _chooseLanguage() async {
    final l10n = _l10n;
    final current = (_me?.preferredLanguage ??
            SediLocaleController.instance.languageCode)
        .toLowerCase();
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.profileLanguageChooseTitle),
        children: [
          for (final code in const ['fa', 'ar', 'en'])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(code),
              child: Row(
                children: [
                  Expanded(child: Text(_formatLanguage(code))),
                  if (code == current)
                    const Icon(Icons.check_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final outcome = await ProfileLanguageChange.apply(
      current: current,
      selected: picked,
      patch: (u) => _profile.patchMe(u, recoverSessionOn401: true),
      locale: SediLocaleController.instance,
    );
    if (!mounted) return;
    if (outcome == ProfileLanguageOutcome.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.profileLanguageChangeFailed)),
      );
      return;
    }
    if (outcome == ProfileLanguageOutcome.changed) {
      // The summary card is text Sedi writes in the account language: fetch it again.
      await _load();
    }
  }

  IconData _sexIcon(String? sex) {
    switch ((sex ?? '').toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return Icons.transgender_rounded;
    }
  }

  Widget _roundGlassButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    double size = 40,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.78),
                  Colors.white.withOpacity(0.30),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
            ),
            child: Icon(icon, size: 20, color: SediGlass.ink),
          ),
        ),
      ),
    );
  }

  Widget _sphereButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool busy = false,
    double size = 46,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: SediGlass.pistachioSphere(),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SediGlass.inkDeep,
                    ),
                  )
                : Icon(icon, size: 22, color: SediGlass.inkDeep),
          ),
        ),
      ),
    );
  }

  /// The active (editing) look: a lit pistachio ring around the box.
  BoxDecoration _activeBox() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      color: Colors.white.withOpacity(0.82),
      border: Border.all(color: const Color(0xFF8FAE3E), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF8FAE3E).withOpacity(0.28),
          spreadRadius: 4,
        ),
        BoxShadow(
          color: const Color(0xFF48551F).withOpacity(0.14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _logoutButton(Gate3Localization l10n) {
    final radius = BorderRadius.circular(28);
    return SediGlass.blur(
      radius: radius,
      sigma: 14,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AuthHelper.performLogout(context: context),
          borderRadius: radius,
          child: Container(
            height: 56,
            decoration: SediGlass.card(radius),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded,
                    size: 24, color: SediPalette.skin700),
                const SizedBox(width: 10),
                Text(
                  l10n.logoutApp,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: SediPalette.skin700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- phone: the number, then the edit box, then the code box under it ----

  Widget _phoneCard(Gate3Localization l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_changingPhone)
          _phoneRow(l10n, number: _me?.phone ?? '—')
        else if (!_otpSent)
          _phoneEditBox(l10n)
        else ...[
          _phoneRow(l10n, number: _pendingNewPhone ?? '—', sent: true),
          const SizedBox(height: 10),
          _codeBox(l10n),
        ],
        if (_phoneFlowError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: AppTheme.dangerRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _phoneFlowError!,
                    style: const TextStyle(
                      color: AppTheme.dangerRed,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_phoneFlowSuccess != null && !_changingPhone)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: SediGlass.ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _phoneFlowSuccess!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The closed row: phone icon, the number (always left-to-right), and the pencil right beside it.
  Widget _phoneRow(
    Gate3Localization l10n, {
    required String number,
    bool sent = false,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.62),
            Colors.white.withOpacity(0.22),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.85)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 26, color: SediGlass.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                // room between the number and the pencil (Javad 2026-10-29: they were touching)
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  number,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (sent)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check_circle_outline_rounded,
                  size: 24, color: Color(0xFF5F7B22)),
            )
          else
            _sphereButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.changePhone,
              size: 44,
              onTap: () => setState(() {
                _changingPhone = true;
                _phoneFlowError = null;
                _phoneFlowSuccess = null;
                _otpSent = false;
              }),
            ),
        ],
      ),
    );
  }

  void _cancelPhoneChange() {
    setState(() {
      _changingPhone = false;
      _otpSent = false;
      _pendingNewPhone = null;
      _phoneFlowError = null;
    });
  }

  /// The number box itself becomes the field (no panel): dial code + number, with cancel and send-code icons.
  Widget _phoneEditBox(Gate3Localization l10n) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 8, 7),
      decoration: _activeBox(),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 26, color: SediGlass.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<A2CountryDialCode>(
                      value: _dial,
                      isDense: true,
                      icon: const Icon(Icons.expand_more_rounded,
                          size: 18, color: SediGlass.ink),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
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
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      enabled: !_phoneBusy,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      cursorColor: SediGlass.ink,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _roundGlassButton(
            icon: Icons.close_rounded,
            tooltip: l10n.cancel,
            onTap: _phoneBusy ? null : _cancelPhoneChange,
          ),
          const SizedBox(width: 6),
          _sphereButton(
            icon: Icons.send_rounded,
            tooltip: l10n.sendPhoneOtp,
            busy: _phoneBusy,
            onTap: _requestPhoneOtp,
          ),
        ],
      ),
    );
  }

  /// The code box opens UNDER the number and closes after a successful verify (or cancel).
  Widget _codeBox(Gate3Localization l10n) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 8, 7),
      decoration: _activeBox(),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 26, color: SediGlass.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: l10n.otpCodeLabel,
              child: _codeField(),
            ),
          ),
          _roundGlassButton(
            icon: Icons.close_rounded,
            tooltip: l10n.cancel,
            onTap: _phoneBusy ? null : _cancelPhoneChange,
          ),
          const SizedBox(width: 6),
          _sphereButton(
            icon: Icons.check_rounded,
            tooltip: l10n.verifyPhoneOtp,
            busy: _phoneBusy,
            onTap: _verifyPhoneOtp,
          ),
        ],
      ),
    );
  }

  /// One field for the 6-digit code (digits only, autofill-ready), shown as a row of dots until typed.
  Widget _codeField() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: _otpCtrl,
        focusNode: _otpFocus,
        enabled: !_phoneBusy,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        cursorColor: SediGlass.ink,
        inputFormatters: [
          // ASCII, Persian and Arabic-Indic digits all become ASCII, capped at the code length.
          TextInputFormatter.withFunction((oldValue, newValue) {
            final digits = OtpInputHelper.sanitize(newValue.text);
            return TextEditingValue(
              text: digits,
              selection: TextSelection.collapsed(offset: digits.length),
            );
          }),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 10,
          color: AppTheme.textPrimary,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '\u2022\u2022\u2022\u2022\u2022\u2022',
          hintStyle: TextStyle(
            fontSize: 22,
            letterSpacing: 10,
            color: Color(0x5948551F),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (_) => _verifyPhoneOtp(),
      ),
    );
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
      final iso = '${me.birthYear!.toString().padLeft(4, '0')}-'
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

  /// Sedi's overall summary of the user: one short paragraph (4 lines at most, justified) and a Memory chip.
  Widget _buildSummaryCard(Gate3Localization l10n) {
    final text = _canonicalSummary.trim();
    final body = text.isEmpty ? l10n.userSummaryEmpty : text;
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: SediGlass.tile(),
                child: const Icon(Icons.auto_awesome_outlined,
                    size: 21, color: SediGlass.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.userSummarySection,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SediGlass.inkDeep,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Gate3MemoryPage(),
                      ),
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.75),
                          Colors.white.withOpacity(0.28),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 22, color: SediGlass.ink),
                        const SizedBox(width: 7),
                        Text(
                          l10n.memoryOpen,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: SediGlass.inkDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}

/// Canonical user-facing summary from `/auth/me/profile-summary` data.
///
/// Contract: `{rows:[{key,status}], facts:[{key,value}], summary:String}`. `rows` are capability and plan-status codes
/// (never shown as prose) and `facts` is structured data for editing UIs. The card shows ONLY `summary`: one short,
/// human paragraph written by the backend about the user's overall status (R-020). An empty result shows the localized
/// empty state.
String canonicalProfileSummaryText(Object? data) {
  if (data is! Map) return '';
  final summary = data['summary'];
  if (summary is! String) return '';
  return summary.trim();
}
