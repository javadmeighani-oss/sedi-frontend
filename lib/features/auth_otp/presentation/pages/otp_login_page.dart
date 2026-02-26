import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/auth_otp_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../services/push/push_service.dart';
import '../../../chat/presentation/pages/chat_page.dart';

enum _OtpStep { request, verify }

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key});

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final AuthOtpService _authOtpService = AuthOtpService();

  _OtpStep _step = _OtpStep.request;
  bool _isLoading = false;
  String _languagePref = 'auto';
  String _requestedPhone = '';
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;
  bool _navigatedAfterSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String _systemLanguage() {
    final locale =
        ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (locale == 'fa' || locale == 'ar') return locale;
    return 'en';
  }

  String _resolvedLanguage() {
    return _languagePref == 'auto' ? _systemLanguage() : _languagePref;
  }

  String _normalizePhone(String input) {
    return input.trim().replaceAll(' ', '').replaceAll('-', '');
  }

  bool _isValidPhone(String phone) {
    final normalized = _normalizePhone(phone);
    return normalized.length >= 8;
  }

  Future<void> _sendCode() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final phone = _normalizePhone(_phoneController.text);
    final language = _resolvedLanguage();

    setState(() => _isLoading = true);
    final response = await _authOtpService.requestOtp(
      phone: phone,
      language: language,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!response.ok) {
      _showMessage(response.errorMessage);
      return;
    }

    _nameController.text = name;
    _requestedPhone = phone;
    _clearOtpInputs();
    setState(() => _step = _OtpStep.verify);
    _startResendCooldown();
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showMessage('Please enter the 6-digit code.');
      return;
    }

    final name = _nameController.text.trim();
    final language = _resolvedLanguage();

    setState(() => _isLoading = true);
    final response = await _authOtpService.verifyOtp(
      phone: _requestedPhone,
      code: code,
      language: language,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!response.ok || response.data == null) {
      _showMessage(response.errorMessage);
      return;
    }

    final verify = response.data!;
    final userId = verify.userId;
    if (userId == null) {
      _showMessage('User ID is missing in verification response.');
      return;
    }

    final existing = await UserProfileManager.loadProfile();
    final verifiedPhone = verify.phone ?? _requestedPhone;
    final profile = existing.copyWith(
      name: name.isEmpty ? existing.name : name,
      phoneNumber: verifiedPhone,
      preferredLanguage: verify.language ?? language,
      userId: userId,
      isVerified: true,
      hasSecurityPassword: false,
    );

    await UserProfileManager.saveProfile(profile);
    await UserPreferences.savePreferredName(profile.name ?? name);
    await UserPreferences.saveLanguagePref(_languagePref);
    await UserPreferences.saveUserLanguage(profile.preferredLanguage);

    if (verify.accessToken != null && verify.accessToken!.isNotEmpty) {
      await AuthService.setToken(verify.accessToken!);
    }

    await tryRegisterStoredTokenAfterLogin();
    if (!mounted) return;
    if (_navigatedAfterSuccess) return;
    _navigatedAfterSuccess = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  Future<void> _resendCode() async {
    if (_resendSecondsLeft > 0 || _isLoading) return;
    setState(() => _phoneController.text = _requestedPhone);
    await _sendCode();
  }

  void _editPhone() {
    _resendTimer?.cancel();
    setState(() {
      _step = _OtpStep.request;
      _resendSecondsLeft = 0;
      _phoneController.text = _requestedPhone;
    });
  }

  void _clearOtpInputs() {
    for (final c in _otpControllers) {
      c.clear();
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBlack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _step == _OtpStep.request
                  ? _buildRequestStep()
                  : _buildVerifyStep(),
            ),
          ),
          if (_isLoading)
            Container(
              color: AppTheme.background.withOpacity(0.4),
              child: const AppLoadingState(label: 'Please wait...'),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Welcome to Sedi',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your phone number',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          _buildTextInput(
            controller: _nameController,
            hint: 'Your name',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextInput(
            controller: _phoneController,
            hint: 'Phone number',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
            ],
            validator: (v) =>
                _isValidPhone(v ?? '') ? null : 'Enter a valid phone number',
          ),
          const SizedBox(height: 16),
          _buildLanguageSelector(),
          const Spacer(),
          _buildPrimaryButton(
            title: 'Send code',
            isLoading: _isLoading,
            onPressed: _sendCode,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Enter verification code',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Code sent to $_requestedPhone',
          style: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: _resendSecondsLeft == 0 ? _resendCode : null,
              child: Text(
                _resendSecondsLeft == 0
                    ? 'Resend'
                    : 'Resend in ${_resendSecondsLeft}s',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _editPhone,
              child: const Text(
                'Edit phone',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildPrimaryButton(
          title: 'Verify',
          isLoading: _isLoading,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 17,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8)),
        filled: true,
        fillColor: AppTheme.backgroundWhite,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderInactive, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderActive, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderActive, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderActive, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderInactive, width: 1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _languagePref,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'auto', child: Text('Auto')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'fa', child: Text('فارسی')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _languagePref = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.borderInactive, width: 1),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.borderActive, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlack,
          disabledBackgroundColor: AppTheme.metalGrey,
          foregroundColor: AppTheme.backgroundWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.backgroundWhite),
                ),
              )
            : Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
