import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/build_info.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/auth_otp_service.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/locale/sedi_locale_registry.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/auth/auth_profile_service.dart';
import '../../../../core/navigation/app_gate_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../data/dto/auth/me_profile.dart';
import '../../../../data/dto/auth/otp_request.dart';
import '../../../../data/dto/auth/otp_verify_response.dart';
import '../../../../services/push/push_service.dart';
import '../a2_hologram_header.dart';
import '../a2_language_sync.dart';
import '../a2_otp_error_mapper.dart';
import '../a2_phone_e164.dart';
import '../a2_stable_enable.dart';
import '../birth_calendar_helper.dart';
import '../gate2_otp_input.dart';
import '../gate2_post_otp_me_failure.dart';
import '../gate2_post_otp_router.dart';
import '../gate2_post_otp_safe_router.dart';
import '../gate2_profile_rules.dart';
import '../gate2_widgets.dart';
import '../otp_login_localization.dart';

/// Gate 2 — Login / Registration with internal multi-step flow.
enum _Gate2Step {
  language,
  accountChoice,
  returningLogin,
  newUserRegistration,
  otpVerification,
  profileCorrection,
}

enum _AccountChoice { returning, newUser }

enum _CorrectionCase {
  returningProfileIncomplete,
  newUserAlreadyRegistered,
}

/// Shown after Gate 1 when session is invalid, or after logout.
/// On success, navigates to Gate 3 via [AppGateRouter.goToHeart].
class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key});

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  final _returningFormKey = GlobalKey<FormState>();
  final _newUserFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpCodeController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final AuthOtpService _authOtpService = AuthOtpService();
  final AuthProfileService _authProfileService = AuthProfileService();

  final A2StableEnableController _languageCta =
      A2StableEnableController(delay: A2StableEnableController.targetDelay);
  final A2StableEnableController _accountCta =
      A2StableEnableController(delay: A2StableEnableController.targetDelay);
  final A2StableEnableController _returningPhoneCta =
      A2StableEnableController(delay: A2StableEnableController.targetDelay);
  final A2StableEnableController _newUserFormCta =
      A2StableEnableController(delay: A2StableEnableController.targetDelay);
  final A2StableEnableController _otpCta =
      A2StableEnableController(delay: A2StableEnableController.targetDelay);
  final A2StableEnableController _completeRegCta =
      A2StableEnableController(delay: A2StableEnableController.targetDelay);

  late final VoidCallback _stableTick;

  _Gate2Step _step = _Gate2Step.language;
  String? _language;
  _AccountChoice? _accountChoice;
  _CorrectionCase? _correctionCase;
  MeProfileDto? _verifiedMeProfile;
  String? _selectedGender;
  int? _birthDay;
  int? _birthMonth;
  int? _birthYear;
  bool _dobPickerOpen = false;
  bool _isLoading = false;
  bool _otpSent = false;
  String _requestedPhone = '';
  bool _phoneVerifiedInSession = false;
  bool _phoneFieldLocked = false;
  bool _navigatedAfterSuccess = false;
  int? _lastOtpRequestStatusCode;
  A2CountryDialCode _dialCode = A2PhoneE164.defaultDialCode;

  OtpLoginLocalization get _l10n =>
      OtpLoginLocalization(_language ?? SediLocaleController.instance.languageCode);

  String get _calendarType =>
      SediLocaleRegistry.resolve(_language ?? SediLocaleController.instance.languageCode)
          .defaultCalendar;

  @override
  void initState() {
    super.initState();
    BuildInfo.logDebugLabel();
    _stableTick = () {
      if (mounted) setState(() {});
    };
    _otpCodeController.addListener(_onInputChanged);
    _nameController.addListener(_onInputChanged);
    _phoneController.addListener(_onInputChanged);
    _languageCta.addListener(_stableTick);
    _accountCta.addListener(_stableTick);
    _returningPhoneCta.addListener(_stableTick);
    _newUserFormCta.addListener(_stableTick);
    _otpCta.addListener(_stableTick);
    _completeRegCta.addListener(_stableTick);
  }

  @override
  void dispose() {
    _otpCodeController.removeListener(_onInputChanged);
    _nameController.removeListener(_onInputChanged);
    _phoneController.removeListener(_onInputChanged);
    _languageCta.removeListener(_stableTick);
    _accountCta.removeListener(_stableTick);
    _returningPhoneCta.removeListener(_stableTick);
    _newUserFormCta.removeListener(_stableTick);
    _otpCta.removeListener(_stableTick);
    _completeRegCta.removeListener(_stableTick);
    _nameController.dispose();
    _phoneController.dispose();
    _otpCodeController.dispose();
    _otpFocusNode.dispose();
    _languageCta.dispose();
    _accountCta.dispose();
    _returningPhoneCta.dispose();
    _newUserFormCta.dispose();
    _otpCta.dispose();
    _completeRegCta.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(_syncStableCtas);
  }

  void _refresh() {
    if (!mounted) return;
    setState(_syncStableCtas);
  }

  void _syncStableCtas() {
    _languageCta.sync(
      isValid: _language != null,
      signature: _language,
    );
    _accountCta.sync(
      isValid: _accountChoice != null,
      signature: _accountChoice,
    );
    _returningPhoneCta.sync(
      isValid: _canSendReturningRaw,
      signature: '${_dialCode.dial}|${_canonicalPhoneFromInput()}',
    );
    _newUserFormCta.sync(
      isValid: _canSendNewUserRaw,
      signature:
          '${_nameController.text.trim()}|$_selectedGender|$_birthDay|$_birthMonth|$_birthYear|${_canonicalPhoneFromInput()}|${_dialCode.dial}',
    );
    _otpCta.sync(
      isValid: _canConfirmRaw,
      signature: OtpInputHelper.sanitize(_otpCodeController.text),
    );
    _completeRegCta.sync(
      isValid: _canCompleteRegistration && !_isLoading,
      signature:
          '${_nameController.text.trim()}|$_selectedGender|$_birthDay|$_birthMonth|$_birthYear|$_requestedPhone',
    );
  }

  Gate2RegistrationDraft get _registrationDraft => Gate2RegistrationDraft(
        name: _nameController.text,
        gender: _selectedGender,
        birthDay: _birthDay,
        birthMonth: _birthMonth,
        birthYear: _birthYear,
        requestedPhone: _requestedPhone,
        phoneVerifiedInSession: _phoneVerifiedInSession,
      );

  String _canonicalPhoneFromInput() {
    return A2PhoneE164.normalize(
      nationalInput: _phoneController.text,
      dialCode: _dialCode,
    );
  }

  String _normalizePhone(String input) {
    return A2PhoneE164.normalize(
      nationalInput: input,
      dialCode: _dialCode,
    );
  }

  String _formatPhoneForDisplay(String phone) {
    return A2PhoneE164.formatForDisplay(phone);
  }

  bool _isValidPhone(String phone) {
    return A2PhoneE164.isValid(
      nationalInput: phone,
      dialCode: _dialCode,
    );
  }

  bool get _hasCompleteDob =>
      _birthDay != null && _birthMonth != null && _birthYear != null;

  bool get _canSendReturningRaw =>
      !_isLoading &&
      !_phoneVerifiedInSession &&
      _isValidPhone(_phoneController.text);

  bool get _canSendNewUserRaw =>
      !_isLoading &&
      !_phoneVerifiedInSession &&
      _nameController.text.trim().isNotEmpty &&
      _selectedGender != null &&
      _hasCompleteDob &&
      _isValidPhone(_phoneController.text);

  bool get _canConfirmRaw =>
      !_isLoading &&
      _step == _Gate2Step.otpVerification &&
      OtpInputHelper.isComplete(_otpCodeController.text);

  bool get _canSendReturning =>
      _canSendReturningRaw && _returningPhoneCta.enabled;

  bool get _canSendNewUser => _canSendNewUserRaw && _newUserFormCta.enabled;

  bool get _canConfirm => _canConfirmRaw && _otpCta.enabled;

  bool get _canCompleteRegistration => _registrationDraft.isComplete &&
      (_isValidPhone(_phoneController.text) || _requestedPhone.isNotEmpty);

  String _formattedDob() {
    if (!_hasCompleteDob) return '';
    return '${_l10n.formatDay(_birthDay!)} | ${_l10n.months[_birthMonth! - 1]} | ${_l10n.formatYear(_birthYear!)}';
  }

  Future<void> _confirmLanguage() async {
    final lang = _language;
    if (lang == null) return;
    await SediLocaleController.instance.setRuntimeLocale(
      lang,
      persistBootstrapCache: true,
    );
    setState(() => _step = _Gate2Step.accountChoice);
  }

  Future<void> _selectLanguage(String code) async {
    await SediLocaleController.instance.setRuntimeLocale(
      code,
      persistBootstrapCache: true,
    );
    setState(() {
      _language = code;
      _syncStableCtas();
    });
  }

  void _confirmAccountChoice() {
    if (_accountChoice == null) return;
    _resetOtpInputsOnly();
    setState(() {
      _otpSent = false;
      _phoneFieldLocked = false;
      if (!_phoneVerifiedInSession) {
        _phoneController.clear();
        _requestedPhone = '';
      }
      _step = _accountChoice == _AccountChoice.returning
          ? _Gate2Step.returningLogin
          : _Gate2Step.newUserRegistration;
    });
  }

  void _resetOtpInputsOnly() {
    _otpCodeController.clear();
  }

  void _resetOtpFlow() {
    _otpSent = false;
    _resetOtpInputsOnly();
  }

  Future<void> _clearVerifiedSession() async {
    await AuthService.clearUserData();
    _phoneVerifiedInSession = false;
    _phoneFieldLocked = false;
    _verifiedMeProfile = null;
    _correctionCase = null;
    _requestedPhone = '';
  }

  Future<void> _goToLanguage() async {
    await _clearVerifiedSession();
    setState(() {
      _language = null;
      _accountChoice = null;
      _resetOtpFlow();
      _phoneController.clear();
      _step = _Gate2Step.language;
    });
  }

  Future<void> _goToAccountChoice({bool clearVerifiedSession = true}) async {
    if (clearVerifiedSession) {
      await _clearVerifiedSession();
    }
    setState(() {
      _correctionCase = null;
      _verifiedMeProfile = null;
      _resetOtpFlow();
      _phoneFieldLocked = false;
      _phoneController.clear();
      _step = _Gate2Step.accountChoice;
    });
  }

  void _handleSystemBack() {
    switch (_step) {
      case _Gate2Step.language:
        break;
      case _Gate2Step.accountChoice:
        _goToLanguage();
        break;
      case _Gate2Step.returningLogin:
      case _Gate2Step.newUserRegistration:
        _goToAccountChoice();
        break;
      case _Gate2Step.otpVerification:
        _backFromOtpVerification();
        break;
      case _Gate2Step.profileCorrection:
        _goToAccountChoice();
        break;
    }
  }

  void _backFromOtpVerification() {
    if (_phoneVerifiedInSession) return;
    setState(() {
      _resetOtpFlow();
      _step = _accountChoice == _AccountChoice.newUser
          ? _Gate2Step.newUserRegistration
          : _Gate2Step.returningLogin;
    });
  }

  Future<void> _sendCode({required bool isNewUser}) async {
    final canSend = isNewUser ? _canSendNewUser : _canSendReturning;
    if (!canSend) return;

    final formKey = isNewUser ? _newUserFormKey : _returningFormKey;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final phone = _normalizePhone(_phoneController.text);
    setState(() => _isLoading = true);
    final response = await _authOtpService.requestOtp(
      phone: phone,
      purpose: isNewUser ? OtpPurpose.registration : OtpPurpose.login,
      language: _language ?? 'en',
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _lastOtpRequestStatusCode = response.statusCode;
    });

    if (!response.ok) {
      _showMessage(A2OtpErrorMapper.mapRequest(
        l10n: _l10n,
        code: response.error?.code,
        message: response.errorMessage,
        statusCode: response.statusCode,
      ));
      return;
    }

    _requestedPhone = phone;
    _resetOtpInputsOnly();
    setState(() {
      _otpSent = true;
      _step = _Gate2Step.otpVerification;
    });
    _showMessage(_l10n.codeSentGeneric);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _otpFocusNode.requestFocus();
      TextInput.finishAutofillContext(shouldSave: true);
    });
  }

  Future<void> _verifyCode() async {
    if (!_canConfirm) return;
    final code = OtpInputHelper.sanitize(_otpCodeController.text);
    if (!OtpInputHelper.isComplete(code)) {
      _showMessage(_l10n.otpIncomplete);
      return;
    }

    setState(() => _isLoading = true);
    final response = await _authOtpService.verifyOtp(
      phone: _requestedPhone,
      code: code,
      purpose: _accountChoice == _AccountChoice.newUser
          ? OtpPurpose.registration
          : OtpPurpose.login,
      language: _language ?? 'en',
    );
    if (!mounted) return;

    if (!response.ok || response.data == null) {
      setState(() => _isLoading = false);
      _showMessage(A2OtpErrorMapper.mapVerify(
        l10n: _l10n,
        code: response.error?.code,
        message: response.errorMessage,
        statusCode: response.statusCode,
      ));
      return;
    }

    final verify = response.data!;
    if (verify.accessToken == null || verify.accessToken!.isEmpty) {
      setState(() => _isLoading = false);
      _showMessage(_l10n.genericOtpVerifyFailed);
      return;
    }

    await AuthService.setTokens(
      accessToken: verify.accessToken!,
      refreshToken: verify.refreshToken,
    );
    if (!await AuthService.hasToken()) {
      setState(() => _isLoading = false);
      _showMessage(_l10n.genericOtpVerifyFailed);
      return;
    }

    _phoneVerifiedInSession = true;
    await _routeAfterVerifiedPhone(
      verify: verify,
      accessToken: verify.accessToken!,
      knownPhoneE164: verify.phone ?? _requestedPhone,
    );
  }

  Future<void> _routeAfterVerifiedPhone({
    required OtpVerifyResponse verify,
    required String accessToken,
    String? knownPhoneE164,
  }) async {
    final meRes = await _authProfileService.fetchMeAfterOtp(
      accessToken: accessToken,
      knownPhoneE164: knownPhoneE164,
    );
    if (!mounted) return;

    final backendConfirmed = meRes.ok && meRes.data != null;
    MeProfileDto? me = backendConfirmed ? meRes.data : null;
    PostOtpMeSource meSource = PostOtpMeSource.backendConfirmed;

    if (me == null) {
      final failureKind = classifyPostOtpMeFailure(meRes);
      if (failureKind != PostOtpMeFailureKind.auth) {
        me = _authProfileService.profileFromOtpVerify(
          verify,
          fallbackPhoneE164: knownPhoneE164 ?? _requestedPhone,
        );
        if (me != null) {
          meSource = PostOtpMeSource.otpFallbackDraft;
        }
      }
    }

    if (me == null) {
      _handlePostOtpMeFailure(meRes);
      return;
    }

    final action = Gate2PostOtpSafeRouter.resolve(
      meSource: meSource,
      isNewUserPath: _accountChoice == _AccountChoice.newUser,
      me: me,
      registrationDraftComplete: _registrationDraft.isComplete,
    );

    switch (action) {
      case Gate2PostOtpAction.enterGate3:
        await _finishWithProfile(me, backendConfirmed: true);
        return;
      case Gate2PostOtpAction.showProfileCorrectionReturning:
        setState(() {
          _isLoading = false;
          _verifiedMeProfile = me;
          _correctionCase = _CorrectionCase.returningProfileIncomplete;
          _step = _Gate2Step.profileCorrection;
        });
        return;
      case Gate2PostOtpAction.showProfileCorrectionAlreadyRegistered:
        setState(() {
          _isLoading = false;
          _verifiedMeProfile = me;
          _correctionCase = _CorrectionCase.newUserAlreadyRegistered;
          _step = _Gate2Step.profileCorrection;
        });
        return;
      case Gate2PostOtpAction.patchRegistrationThenEnterGate3:
        await _completeNewUserRegistration(skipOtp: true);
        return;
      case Gate2PostOtpAction.showRegistrationCompletion:
        _goToRegistrationCompletionAfterOtp();
        return;
    }
  }

  void _handlePostOtpMeFailure(ApiResponse<MeProfileDto> meRes) {
    setState(() => _isLoading = false);
    switch (classifyPostOtpMeFailure(meRes)) {
      case PostOtpMeFailureKind.auth:
        _showMessage(_l10n.sessionAuthFailed);
        return;
      case PostOtpMeFailureKind.parse:
        _showMessage(_l10n.profileParseFailed);
        return;
      case PostOtpMeFailureKind.fetch:
        _showMessage(_sanitizeMeFetchError(meRes.errorMessage));
        return;
    }
  }

  void _goToRegistrationCompletionAfterOtp() {
    if (_requestedPhone.isNotEmpty) {
      _applyVerifiedPhoneToField(_requestedPhone);
    }
    setState(() {
      _isLoading = false;
      _phoneFieldLocked = true;
      _phoneVerifiedInSession = true;
      _step = _Gate2Step.newUserRegistration;
      _syncStableCtas();
    });
  }

  void _applyVerifiedPhoneToField(String e164) {
    final cleaned = A2PhoneE164.stripFormatting(e164);
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1);
      for (final code in A2PhoneE164.dialCodes) {
        if (digits.startsWith(code.dial)) {
          _dialCode = code;
          break;
        }
      }
    }
    _phoneController.text = _formatPhoneForDisplay(cleaned);
  }

  Future<void> _completeNewUserRegistration({bool skipOtp = false}) async {
    if (!skipOtp) {
      if (!(_newUserFormKey.currentState?.validate() ?? false)) return;
    } else if (!_canCompleteRegistration) {
      _goToRegistrationCompletionAfterOtp();
      return;
    }

    setState(() => _isLoading = true);

    final iso = BirthCalendarHelper.toIsoDate(
      calendarType: _calendarType,
      day: _birthDay!,
      month: _birthMonth!,
      year: _birthYear!,
    );
    if (iso == null) {
      setState(() => _isLoading = false);
      _goToRegistrationCompletionAfterOtp();
      _showMessage(_l10n.dobRequired);
      return;
    }

    final patch = MeUpdateDto(
      name: _nameController.text.trim(),
      sex: _selectedGender,
      preferredLanguage: _language ?? 'en',
      calendarType: _calendarType,
      birthDay: _birthDay,
      birthMonth: _birthMonth,
      birthYear: _birthYear,
      dateOfBirth: iso,
    );
    final patchRes = await _authProfileService.patchMe(
      patch,
      recoverSessionOn401: false,
      knownPhoneE164: _requestedPhone,
    );
    if (!mounted) return;
    if (!patchRes.ok || patchRes.data == null) {
      setState(() => _isLoading = false);
      _goToRegistrationCompletionAfterOtp();
      _showMessage(_sanitizeProfileError(
        patchRes.errorMessage,
        statusCode: patchRes.statusCode,
        errorCode: patchRes.error?.code,
      ));
      return;
    }

    final accessToken = await AuthService.getToken();
    final meRes = accessToken == null || accessToken.isEmpty
        ? ApiResponse<MeProfileDto>(
            ok: false,
            error: const ApiError(
              code: 'AUTH_ERROR',
              message: 'Missing access token',
            ),
          )
        : await _authProfileService.fetchMeAfterOtp(
            accessToken: accessToken,
            knownPhoneE164: _requestedPhone,
          );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!meRes.ok || meRes.data == null) {
      _goToRegistrationCompletionAfterOtp();
      _showMessage(_sanitizeMeFetchError(meRes.errorMessage));
      return;
    }

    final me = meRes.data!;
    if (!Gate2ProfileRules.isProfileComplete(me)) {
      _goToRegistrationCompletionAfterOtp();
      _showMessage(_l10n.profileIncomplete);
      return;
    }

    await _authProfileService.cacheProfileFromBackend(me);
    await _finishWithProfile(me, backendConfirmed: true);
  }

  Future<void> _finishWithProfile(
    MeProfileDto me, {
    required bool backendConfirmed,
  }) async {
    if (!backendConfirmed) {
      return;
    }
    final sync = await _syncPreferredLanguageWithBackend(me);
    if (!sync.mayEnterA3 || sync.confirmedProfile == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Stay in A2. Do not overwrite selected runtime locale with stale backend.
      _showMessage(_l10n.languageSyncFailed);
      return;
    }
    me = sync.confirmedProfile!;
    await SediLocaleController.instance.reconcileFromBackendConfirmed(
      me.preferredLanguage ?? _language,
    );
    await _authProfileService.cacheProfileFromBackend(me);
    await UserPreferences.savePreferredName(me.name ?? '');

    await tryRegisterStoredTokenAfterLogin();
    if (!mounted) return;
    if (_navigatedAfterSuccess) return;
    _navigatedAfterSuccess = true;
    AppGateRouter.goToHeart(context);
  }

  /// After GET /auth/me, PATCH preferred_language when A2 selection differs.
  /// On PATCH failure: block A3; preserve selected runtime locale.
  Future<A2LanguageSyncResult> _syncPreferredLanguageWithBackend(
    MeProfileDto me,
  ) async {
    if (!A2LanguageSync.needsPatch(
      backendMe: me,
      selectedLanguage: _language,
    )) {
      return A2LanguageSyncResult(
        outcome: A2LanguageSyncOutcome.matched,
        profile: me,
      );
    }
    final selected = _language!.trim();
    final patchRes = await _authProfileService.patchMe(
      A2LanguageSync.patchDto(selected),
      recoverSessionOn401: false,
      knownPhoneE164: me.phone ?? _requestedPhone,
    );
    return A2LanguageSync.classifyAfterPatchAttempt(
      backendMeBeforePatch: me,
      selectedLanguage: selected,
      patchOk: patchRes.ok && patchRes.data != null,
      patchedProfile: patchRes.data,
    );
  }

  void _startCompleteRegistrationFromCorrection() {
    if (_requestedPhone.isNotEmpty) {
      _applyVerifiedPhoneToField(_requestedPhone);
    }
    setState(() {
      _accountChoice = _AccountChoice.newUser;
      _phoneFieldLocked = true;
      _phoneVerifiedInSession = true;
      _correctionCase = null;
      _verifiedMeProfile = null;
      _resetOtpFlow();
      _step = _Gate2Step.newUserRegistration;
      _syncStableCtas();
    });
  }

  Future<void> _continueWithExistingAccount() async {
    setState(() => _isLoading = true);
    final meRes = await _authProfileService.fetchMe(recoverSessionOn401: false);
    if (!mounted) return;

    if (!meRes.ok || meRes.data == null) {
      setState(() => _isLoading = false);
      _handlePostOtpMeFailure(meRes);
      return;
    }

    final me = meRes.data!;
    await _finishWithProfile(me, backendConfirmed: true);
    if (mounted) setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.gate2ButtonOlive,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _sanitizeProfileError(
    String message, {
    int? statusCode,
    String? errorCode,
  }) {
    if (message.toLowerCase().contains('timeout')) {
      return _l10n.networkError;
    }
    if (statusCode == 401 || statusCode == 403 || errorCode == 'AUTH_ERROR') {
      return _l10n.sessionAuthFailed;
    }
    if (errorCode == 'PARSE_ERROR' ||
        message.toLowerCase().contains('parse') ||
        message.toLowerCase().contains('profile data')) {
      return _l10n.profileParseFailed;
    }
    if (statusCode == 422) {
      return _l10n.profileIncomplete;
    }
    return _l10n.profileSyncFailed;
  }

  String _sanitizeMeFetchError(String message) {
    if (message.toLowerCase().contains('timeout')) {
      return _l10n.networkError;
    }
    return _l10n.profileFetchFailed;
  }

  void _openDobPicker() {
    final defaults = BirthCalendarHelper.defaultSelection(_calendarType);
    setState(() {
      _dobPickerOpen = !_dobPickerOpen;
      if (_dobPickerOpen) {
        _birthDay ??= defaults[0];
        _birthMonth ??= defaults[1];
        _birthYear ??= defaults[2];
      }
      _syncStableCtas();
    });
  }

  void _showGenderPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.gate2CardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.gate2RadiusCard),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in ['male', 'female', 'other'])
              ListTile(
                title: Text(_l10n.genderLabel(value)),
                onTap: () {
                  setState(() {
                    _selectedGender = value;
                    _syncStableCtas();
                  });
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Global locale authority drives direction; A2 selection updates it immediately.
    final direction = SediLocaleController.instance.current.textDirection;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleSystemBack();
      },
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          backgroundColor: AppTheme.a2PageBackground,
          resizeToAvoidBottomInset: true,
          body: Gate2Widgets.pageShell(
            isLoading: _isLoading,
            loadingLabel: _l10n.pleaseWait,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const SediSceneBackdrop(),
                SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('$_step-${_correctionCase ?? ''}'),
                  child: _buildStep(),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Gate2Step.language:
        return _buildLanguageStep();
      case _Gate2Step.accountChoice:
        return _buildAccountChoiceStep();
      case _Gate2Step.returningLogin:
        return _buildReturningLoginStep();
      case _Gate2Step.newUserRegistration:
        return _buildNewUserStep();
      case _Gate2Step.otpVerification:
        return _buildOtpVerificationStep();
      case _Gate2Step.profileCorrection:
        return _buildCorrectionStep();
    }
  }

  Widget _buildScrollShell(
    Widget child, {
    bool hero = false,
    Gate3InteractionState orbState = Gate3InteractionState.idle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        // Short screens keep the form above the fold: small static hologram.
        final tall = constraints.maxHeight >= 720;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 28 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Short screens: only the first (language) step keeps a small
                // static hologram; later steps keep the form above the fold.
                if (tall || hero)
                  A2HologramHeader(
                    l10n: _l10n,
                    hero: hero && tall,
                    state: orbState,
                    animate: tall,
                  ),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageStep() {
    return _buildScrollShell(
      Gate2Widgets.centeredLuxuryCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gate2Widgets.languageButton(
              label: 'العربية',
              selected: _language == 'ar',
              onTap: () => _selectLanguage('ar'),
            ),
            Gate2Widgets.languageButton(
              label: 'English',
              selected: _language == 'en',
              onTap: () => _selectLanguage('en'),
            ),
            Gate2Widgets.languageButton(
              label: 'فارسی',
              selected: _language == 'fa',
              onTap: () => _selectLanguage('fa'),
            ),
            const SizedBox(height: 24),
            Gate2Widgets.primaryButton(
              label: _l10n.confirm,
              enabled: _languageCta.enabled,
              onPressed: _confirmLanguage,
            ),
          ],
        ),
      ),
      hero: true,
    );
  }

  Widget _buildAccountChoiceStep() {
    return _buildScrollShell(
      Gate2Widgets.centeredLuxuryCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gate2Widgets.backLink(
              label: _l10n.back,
              onPressed: _goToLanguage,
            ),
            Gate2Widgets.stepTitle(
              _l10n.enterSediTitle,
              subtitle: _l10n.enterSediSubtitle,
            ),
            const SizedBox(height: 24),
            Gate2Widgets.accountOptionCard(
              title: _l10n.haveAccountTitle,
              description: _l10n.haveAccountDesc,
              icon: Icons.login_rounded,
              selected: _accountChoice == _AccountChoice.returning,
              onTap: () => setState(() {
                _accountChoice = _AccountChoice.returning;
                _syncStableCtas();
              }),
            ),
            Gate2Widgets.accountOptionCard(
              title: _l10n.noAccountTitle,
              description: _l10n.noAccountDesc,
              icon: Icons.person_add_alt_1_outlined,
              selected: _accountChoice == _AccountChoice.newUser,
              onTap: () => setState(() {
                _accountChoice = _AccountChoice.newUser;
                _syncStableCtas();
              }),
            ),
            const SizedBox(height: 12),
            Gate2Widgets.primaryButton(
              label: _l10n.confirm,
              enabled: _accountCta.enabled,
              onPressed: _confirmAccountChoice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturningLoginStep() {
    return _buildScrollShell(
      Gate2Widgets.centeredLuxuryCard(
        child: Form(
          key: _returningFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Gate2Widgets.backLink(
                label: _l10n.backToAccountChoice,
                onPressed: _goToAccountChoice,
              ),
              Gate2Widgets.stepTitle(
                _l10n.returningTitle,
                subtitle: _l10n.returningSubtitle,
              ),
              const SizedBox(height: 24),
              Gate2Widgets.phoneField(
                controller: _phoneController,
                hint: _l10n.mobileNumber,
                dialCode: _dialCode,
                onDialCodeChanged: (code) => setState(() {
                  _dialCode = code;
                  _syncStableCtas();
                }),
                validator: (v) =>
                    _isValidPhone(v ?? '') ? null : _l10n.invalidPhone,
                onChanged: (_) => _onInputChanged(),
              ),
              const SizedBox(height: 16),
              Center(
                child: Gate2Widgets.primaryButton(
                  label: _l10n.send,
                  enabled: _canSendReturning,
                  fullWidth: false,
                  onPressed: () => _sendCode(isNewUser: false),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewUserStep() {
    final showOtpFlow = !_phoneVerifiedInSession;

    return _buildScrollShell(
      Gate2Widgets.centeredLuxuryCard(
        child: Form(
          key: _newUserFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Gate2Widgets.backLink(
                label: _l10n.backToAccountChoice,
                onPressed: _goToAccountChoice,
              ),
              Gate2Widgets.stepTitle(_l10n.newUserTitle),
              const SizedBox(height: 24),
              Gate2Widgets.textField(
                controller: _nameController,
                hint: _l10n.name,
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? _l10n.nameRequired : null,
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 12),
              FormField<String>(
                validator: (_) =>
                    _selectedGender == null ? _l10n.genderRequired : null,
                builder: (state) => Gate2Widgets.tapField(
                  hint: _l10n.gender,
                  value: _selectedGender != null
                      ? _l10n.genderLabel(_selectedGender!)
                      : '',
                  icon: Icons.wc_outlined,
                  onTap: _showGenderPicker,
                  hasError: state.hasError,
                  errorText: state.errorText,
                ),
              ),
              const SizedBox(height: 12),
              FormField<void>(
                validator: (_) =>
                    !_hasCompleteDob ? _l10n.dobRequired : null,
                builder: (state) => Column(
                  children: [
                    Gate2Widgets.tapField(
                      hint: _l10n.selectDateOfBirth,
                      value: _hasCompleteDob ? _formattedDob() : '',
                      icon: Icons.calendar_today_outlined,
                      onTap: _openDobPicker,
                      hasError: state.hasError,
                      errorText: state.errorText,
                    ),
                    if (_dobPickerOpen)
                      Gate2Widgets.dobPicker(
                        l10n: _l10n,
                        calendarType: _calendarType,
                        day: _birthDay ??
                            BirthCalendarHelper.defaultSelection(
                                _calendarType)[0],
                        month: _birthMonth ??
                            BirthCalendarHelper.defaultSelection(
                                _calendarType)[1],
                        year: _birthYear ??
                            BirthCalendarHelper.defaultSelection(
                                _calendarType)[2],
                        onDay: (v) => setState(() {
                          _birthDay = v;
                          _syncStableCtas();
                        }),
                        onMonth: (v) => setState(() {
                          _birthMonth = v;
                          final maxDay = BirthCalendarHelper.daysInMonth(
                            calendarType: _calendarType,
                            year: _birthYear!,
                            month: v,
                          );
                          if (_birthDay! > maxDay) _birthDay = maxDay;
                          _syncStableCtas();
                        }),
                        onYear: (v) => setState(() {
                          _birthYear = v;
                          final maxDay = BirthCalendarHelper.daysInMonth(
                            calendarType: _calendarType,
                            year: v,
                            month: _birthMonth!,
                          );
                          if (_birthDay! > maxDay) _birthDay = maxDay;
                          _syncStableCtas();
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_phoneVerifiedInSession && _phoneFieldLocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _l10n.phoneVerifiedLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.gate2TextMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              Gate2Widgets.phoneField(
                controller: _phoneController,
                hint: _l10n.mobileNumber,
                dialCode: _dialCode,
                dialCodeEnabled: !_phoneFieldLocked,
                onDialCodeChanged: (code) => setState(() {
                  _dialCode = code;
                  _syncStableCtas();
                }),
                readOnly: _phoneFieldLocked,
                validator: (v) {
                  if (_phoneVerifiedInSession && _requestedPhone.isNotEmpty) {
                    return null;
                  }
                  return _isValidPhone(v ?? '') ? null : _l10n.invalidPhone;
                },
                onChanged: (_) => _onInputChanged(),
              ),
              const SizedBox(height: 16),
              if (showOtpFlow)
                Center(
                  child: Gate2Widgets.primaryButton(
                    label: _l10n.send,
                    enabled: _canSendNewUser,
                    fullWidth: false,
                    onPressed: () => _sendCode(isNewUser: true),
                  ),
                )
              else
                Gate2Widgets.primaryButton(
                  label: _l10n.completeRegistration,
                  enabled: _completeRegCta.enabled,
                  onPressed: _completeNewUserRegistration,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpVerificationStep() {
    final backLabel = _accountChoice == _AccountChoice.newUser
        ? _l10n.backToRegistration
        : _l10n.changePhoneNumber;

    return _buildScrollShell(
      Gate2Widgets.centeredLuxuryCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Gate2Widgets.backLink(
              label: backLabel,
              onPressed: _backFromOtpVerification,
            ),
            Gate2Widgets.stepTitle(_l10n.sentCode),
            const SizedBox(height: 24),
            Gate2Widgets.otpSection(
              l10n: _l10n,
              controller: _otpCodeController,
              focusNode: _otpFocusNode,
              active: true,
              showTitle: false,
              onChanged: (_) => _refresh(),
            ),
            const SizedBox(height: 20),
            Gate2Widgets.primaryButton(
              label: _l10n.confirm,
              enabled: _canConfirm,
              onPressed: _verifyCode,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      orbState: Gate3InteractionState.listening,
    );
  }

  Widget _buildCorrectionStep() {
    final correction = _correctionCase;
    if (correction == null) {
      return const SizedBox.shrink();
    }

    final message = correction == _CorrectionCase.returningProfileIncomplete
        ? _l10n.returningProfileIncompleteMessage
        : _l10n.newUserAlreadyRegisteredMessage;

    final primaryLabel = correction == _CorrectionCase.returningProfileIncomplete
        ? _l10n.completeRegistration
        : _l10n.continueToAccount;

    final onPrimary = correction == _CorrectionCase.returningProfileIncomplete
        ? _startCompleteRegistrationFromCorrection
        : _continueWithExistingAccount;

    return _buildScrollShell(
      Gate2Widgets.centeredLuxuryCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Gate2Widgets.stepTitle(_l10n.enterSediTitle),
            const SizedBox(height: 24),
            Gate2Widgets.correctionPanel(
              message: message,
              primaryLabel: primaryLabel,
              onPrimary: onPrimary,
              secondaryLabel: _l10n.backToAccountChoice,
              onSecondary: _goToAccountChoice,
            ),
          ],
        ),
      ),
    );
  }
}

extension on OtpLoginLocalization {
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;
}
