import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../core/config/app_config.dart';
import '../../../chat/chat_service.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../chat/presentation/widgets/sedi_header.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordValid = false;
  bool _isFormValid = false;
  bool _isSubmitting = false;

  String _getSystemLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.toLowerCase();
    if (languageCode == 'fa' || languageCode == 'ar') {
      return languageCode;
    }
    return 'fa';
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _passwordController.addListener(_validatePassword);
    _checkOnboardingStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
      _validatePassword();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final profile = await UserProfileManager.loadProfile();
      final hasName = profile.name != null && profile.name!.isNotEmpty;
      final hasPassword = profile.securityPassword != null && 
                          profile.securityPassword!.isNotEmpty;
      final isVerified = profile.isVerified || profile.hasSecurityPassword;
      final hasCompletedOnboarding = hasName && hasPassword && isVerified;
      
      if (hasCompletedOnboarding && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      }
    } catch (e) {
      // Continue with onboarding page
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final isValid = password.length >= 6;
    
    if (mounted) {
      setState(() {
        _isPasswordValid = isValid;
        _validateForm();
      });
    }
  }

  void _validateForm() {
    final nameText = _nameController.text.trim();
    final nameValid = nameText.isNotEmpty;
    final isValid = nameValid && _isPasswordValid;
    
    if (mounted) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _submitForm() async {
    print('[OnboardingPage] ========== SUBMIT FORM START ==========');
    
    if (_isSubmitting || !_isFormValid) {
      print('[OnboardingPage] ⚠️ Submit blocked: _isSubmitting=$_isSubmitting, _isFormValid=$_isFormValid');
      return;
    }
    
    if (!(_formKey.currentState?.validate() ?? false)) {
      print('[OnboardingPage] ⚠️ Form validation failed');
      return;
    }

    if (!mounted) {
      print('[OnboardingPage] ⚠️ Widget not mounted, aborting');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final systemLanguage = _getSystemLanguage();
    
    print('[OnboardingPage] Form data:');
    print('[OnboardingPage]   - Name: "$name" (length: ${name.length})');
    print('[OnboardingPage]   - Password: length=${password.length}');
    print('[OnboardingPage]   - Language: $systemLanguage');

    try {
      print('[OnboardingPage] Calling ChatService.setupOnboarding...');
      final chatService = ChatService();
      final result = await chatService.setupOnboarding(
        password,
        systemLanguage,
        name: name,  // CRITICAL: Pass name to backend for GPT personalization
      );
      
      print('[OnboardingPage] ========== BACKEND RESPONSE RECEIVED ==========');
      print('[OnboardingPage] Response keys: ${result.keys.toList()}');
      print('[OnboardingPage] user_id: ${result['user_id']} (type: ${result['user_id']?.runtimeType})');
      print('[OnboardingPage] message: ${result['message']}');
      print('[OnboardingPage] language: ${result['language']}');
      
      // CRITICAL: Check user_id - this is the blocking issue
      if (!AppConfig.useLocalMode && result['user_id'] == null) {
        print('[OnboardingPage] ❌ ERROR: user_id is null in response');
        print('[OnboardingPage] Response: $result');
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Error registering. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      print('[OnboardingPage] ✅ user_id received: ${result['user_id']}');
      
      // Create profile with all data
      final profile = UserProfile(
        name: name.isNotEmpty ? name : null,
        securityPassword: password,
        preferredLanguage: result['language']?.toString() ?? systemLanguage,
        userId: result['user_id'] as int?,
        hasSecurityPassword: true,
        securityPasswordSetAt: DateTime.now(),
        isVerified: true,
      );
      
      print('[OnboardingPage] Profile created:');
      print('[OnboardingPage]   - name: "${profile.name}"');
      print('[OnboardingPage]   - userId: ${profile.userId}');
      print('[OnboardingPage]   - language: ${profile.preferredLanguage}');
      print('[OnboardingPage]   - hasSecurityPassword: ${profile.hasSecurityPassword}');
      print('[OnboardingPage]   - isVerified: ${profile.isVerified}');
      
      print('[OnboardingPage] Saving profile to local storage...');
      final saveResult = await UserProfileManager.saveProfile(profile);
      print('[OnboardingPage] Profile save result: $saveResult');
      
      // Verify profile was saved
      final savedProfile = await UserProfileManager.loadProfile();
      print('[OnboardingPage] Verified saved profile:');
      print('[OnboardingPage]   - name: "${savedProfile.name}"');
      print('[OnboardingPage]   - userId: ${savedProfile.userId}');
      print('[OnboardingPage]   - language: ${savedProfile.preferredLanguage}');
      
      if (!mounted) {
        print('[OnboardingPage] ⚠️ Widget unmounted before navigation');
        return;
      }
      
      // CRITICAL: Verify user_id is saved before navigation
      final verifyProfile = await UserProfileManager.loadProfile();
      if (verifyProfile.userId == null) {
        print('[OnboardingPage] ❌ CRITICAL ERROR: user_id is null after save!');
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving profile. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      print('[OnboardingPage] ✅ Profile verified - userId: ${verifyProfile.userId}');
      
      final initialMessage = result['message']?.toString() ?? '';
      print('[OnboardingPage] Initial message: "$initialMessage"');
      print('[OnboardingPage] Navigating to ChatPage...');
      
      // CRITICAL: Use pushReplacement to close onboarding window
      // Navigation happens AFTER profile is saved and verified
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatPage(initialMessage: initialMessage),
        ),
      );
      
      print('[OnboardingPage] ✅ Navigation completed');
      print('[OnboardingPage] ========== SUBMIT FORM SUCCESS ==========');
      
    } catch (e, stackTrace) {
      print('[OnboardingPage] ========== SUBMIT FORM ERROR ==========');
      print('[OnboardingPage] ❌ ERROR: $e');
      print('[OnboardingPage] Stack trace: $stackTrace');
      print('[OnboardingPage] ========== END ERROR ==========');
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerWidth = screenSize.width * 0.9;
    final containerHeight = 320.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              child: SediHeader(
                isThinking: false,
                isAlert: false,
                size: 134.4,
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: containerWidth,
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.metalGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildNameSection(),
                          const SizedBox(height: 12),
                          _buildPasswordSection(),
                          const Spacer(),
                          _buildSubmitButton(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            'Name',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryBlack, width: 1.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.metalGrey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: AppTheme.textPrimary.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
              textDirection: TextDirection.ltr,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            'Security password (minimum 6 characters)',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryBlack, width: 1.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.metalGrey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
            ),
            child: TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Enter security password',
                hintStyle: TextStyle(color: AppTheme.textPrimary.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _isPasswordValid
                    ? Icon(Icons.check_circle, color: AppTheme.pistachioGreen, size: 20)
                    : null,
              ),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
              obscureText: true,
              textDirection: TextDirection.ltr,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter security password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    const buttonSize = 58.0;
    const iconSize = 34.0;
    final isEnabled = _isFormValid && !_isSubmitting;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? _submitForm : null,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.primaryBlack : AppTheme.metalGrey,
          shape: BoxShape.circle,
        ),
        child: _isSubmitting
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundWhite),
                  ),
                ),
              )
            : Icon(
                Icons.check,
                color: AppTheme.backgroundWhite,
                size: iconSize,
              ),
      ),
    );
  }
}
