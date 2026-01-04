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

/// ============================================
/// OnboardingPage - صفحه تنظیمات اولیه
/// ============================================
/// 
/// RESPONSIBILITY:
/// - دریافت نام و رمز از کاربر
/// - زبان از تنظیمات سیستم تشخیص داده می‌شود
/// - طراحی: ترنسپرنت پایین، رنگ خاکستری
/// - دو کادر مستطیلی مشکی با داخل خاکستری ترنسپرنت
/// - آیکن تایید در پایین
/// ============================================

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Validation state
  bool _isPasswordValid = false;
  bool _isFormValid = false;
  bool _isSubmitting = false;

  /// Get system language or default to 'fa'
  String _getSystemLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.toLowerCase();
    
    // Map system language to our supported languages
    if (languageCode == 'fa' || languageCode == 'ar') {
      return languageCode;
    }
    // Default to Persian for other languages
    return 'fa';
  }

  /// Check if text contains Persian or Arabic characters
  bool _containsPersianOrArabic(String text) {
    final persianArabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return persianArabicRegex.hasMatch(text);
  }

  /// Translate common error messages to user's language
  String _translateErrorMessage(String errorMessage, String language) {
    final errorLower = errorMessage.toLowerCase();
    
    if (language == 'fa') {
      if (errorLower.contains('password') && errorLower.contains('6')) {
        return 'رمز عبور باید حداقل 6 کاراکتر باشد.';
      } else if (errorLower.contains('server error') || errorLower.contains('500')) {
        return 'خطای سرور. لطفاً بعداً دوباره تلاش کنید.';
      } else if (errorLower.contains('connection') || errorLower.contains('timeout')) {
        return 'خطا در اتصال به سرور. لطفاً اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';
      } else if (errorLower.contains('invalid request') || errorLower.contains('400')) {
        return 'درخواست نامعتبر. لطفاً اطلاعات را بررسی کنید.';
      } else if (errorLower.contains('authentication') || errorLower.contains('401')) {
        return 'خطا در احراز هویت. لطفاً دوباره تلاش کنید.';
      } else if (errorLower.contains('validation')) {
        return 'خطا در اعتبارسنجی. لطفاً اطلاعات را بررسی کنید.';
      } else if (errorLower.contains('unavailable') || errorLower.contains('503')) {
        return 'سرویس موقتاً در دسترس نیست. لطفاً بعداً دوباره تلاش کنید.';
      }
      return 'خطا در ثبت اطلاعات. لطفاً دوباره تلاش کنید.';
    } else if (language == 'ar') {
      if (errorLower.contains('password') && errorLower.contains('6')) {
        return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.';
      } else if (errorLower.contains('server error') || errorLower.contains('500')) {
        return 'خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
      } else if (errorLower.contains('connection') || errorLower.contains('timeout')) {
        return 'خطأ في الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
      } else if (errorLower.contains('invalid request') || errorLower.contains('400')) {
        return 'طلب غير صالح. يرجى التحقق من المعلومات.';
      } else if (errorLower.contains('authentication') || errorLower.contains('401')) {
        return 'خطأ في المصادقة. يرجى المحاولة مرة أخرى.';
      } else if (errorLower.contains('validation')) {
        return 'خطأ في التحقق. يرجى التحقق من المعلومات.';
      } else if (errorLower.contains('unavailable') || errorLower.contains('503')) {
        return 'الخدمة غير متاحة مؤقتاً. يرجى المحاولة مرة أخرى لاحقاً.';
      }
      return 'خطأ في تسجيل المعلومات. يرجى المحاولة مرة أخرى.';
    }
    
    return errorMessage; // Return original if language not supported
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _passwordController.addListener(_validatePassword);
    // Check if user has already completed onboarding
    _checkOnboardingStatus();
    // Initial validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
      _validatePassword();
    });
  }

  /// Check if user has already completed onboarding
  /// If yes, navigate directly to ChatPage
  Future<void> _checkOnboardingStatus() async {
    try {
      final profile = await UserProfileManager.loadProfile();
      
      final hasName = profile.name != null && profile.name!.isNotEmpty;
      final hasPassword = profile.securityPassword != null && 
                          profile.securityPassword!.isNotEmpty;
      final isVerified = profile.isVerified || profile.hasSecurityPassword;
      
      final hasCompletedOnboarding = hasName && hasPassword && isVerified;
      
      print('[OnboardingPage] Checking if onboarding already completed:');
      print('[OnboardingPage] - hasName: $hasName');
      print('[OnboardingPage] - hasPassword: $hasPassword');
      print('[OnboardingPage] - isVerified: $isVerified');
      print('[OnboardingPage] - hasCompletedOnboarding: $hasCompletedOnboarding');
      
      if (hasCompletedOnboarding && mounted) {
        print('[OnboardingPage] ✅ Onboarding already completed - navigating to ChatPage');
        // User has already completed onboarding, navigate to ChatPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ChatPage(),
          ),
        );
      }
    } catch (e) {
      print('[OnboardingPage] Error checking onboarding status: $e');
      // If error, continue with onboarding page
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
    // Password requirements:
    // - At least 6 characters (any characters allowed)
    final hasMinLength = password.length >= 6;
    
    final isValid = hasMinLength;
    
    print('[OnboardingPage] _validatePassword - password: "${password.replaceAll(RegExp(r'.'), '*')}" (length: ${password.length}), valid: $isValid');
    print('[OnboardingPage] _validatePassword - hasMinLength: $hasMinLength');
    
    if (mounted) {
      setState(() {
        _isPasswordValid = isValid;
        _validateForm();
      });
    }
  }

  void _validateForm() {
    final nameText = _nameController.text.trim();
    final nameValid = nameText.isNotEmpty && nameText.length >= 2;
    final isValid = nameValid && _isPasswordValid;
    
    print('[OnboardingPage] _validateForm - name: "$nameText" (valid: $nameValid), password valid: $_isPasswordValid, form valid: $isValid');
    
    if (mounted) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _submitForm() async {
    print('[OnboardingPage] ========== _submitForm START ==========');
    print('[OnboardingPage] Form valid: $_isFormValid');
    print('[OnboardingPage] Submitting: $_isSubmitting');
    print('[OnboardingPage] Name: "${_nameController.text.trim()}"');
    print('[OnboardingPage] Password: "${_passwordController.text}" (length: ${_passwordController.text.length})');
    print('[OnboardingPage] Password valid: $_isPasswordValid');
    
    // Prevent double submission
    if (_isSubmitting) {
      print('[OnboardingPage] Already submitting, ignoring tap');
      return;
    }
    
    // Check custom validation first (faster)
    if (!_isFormValid) {
      print('[OnboardingPage] Custom validation failed - _isFormValid: $_isFormValid');
      // Try to validate form state to show error messages
      _formKey.currentState?.validate();
      return;
    }
    
    // Validate form state (for error messages)
    final formValid = _formKey.currentState?.validate() ?? false;
    print('[OnboardingPage] FormState validation: $formValid');
    
    if (!formValid) {
      print('[OnboardingPage] FormState validation failed');
      return;
    }

    // Set submitting state
    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });
    print('[OnboardingPage] Set _isSubmitting = true');

    try {
      final chatService = ChatService();
      
      // Get system language
      final systemLanguage = _getSystemLanguage();
      
      // Setup onboarding with backend (name no longer sent to backend)
      print('[OnboardingPage] Calling setupOnboarding...');
      print('[OnboardingPage] Password length: ${_passwordController.text.length}');
      print('[OnboardingPage] Language: $systemLanguage');
      
      final result = await chatService.setupOnboarding(
        _passwordController.text,
        systemLanguage,
      );
      
      print('[OnboardingPage] setupOnboarding result: $result');
      print('[OnboardingPage] user_id: ${result['user_id']}');
      print('[OnboardingPage] message: ${result['message']}');
      print('[OnboardingPage] useLocalMode: ${AppConfig.useLocalMode}');

      // Check if onboarding was successful
      // In local mode, user_id can be null (that's okay)
      // In backend mode, user_id must not be null for success
      if (result['user_id'] == null && !AppConfig.useLocalMode) {
        // Backend error - show error message and reset state
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          
          // Show error message - translate if needed
          final errorMessage = result['message']?.toString() ?? 'Error registering information. Please try again.';
          print('[OnboardingPage] Backend error: $errorMessage');
          
          // Translate error message based on system language
          String displayMessage = errorMessage;
          final systemLanguage = _getSystemLanguage();
          
          // If error message is in English, try to translate to user's language
          if (systemLanguage == 'fa' && !_containsPersianOrArabic(errorMessage)) {
            displayMessage = _translateErrorMessage(errorMessage, 'fa');
          } else if (systemLanguage == 'ar' && !_containsPersianOrArabic(errorMessage)) {
            displayMessage = _translateErrorMessage(errorMessage, 'ar');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; // Don't navigate, stay on page
      }
      
      // Save user profile locally (name stored locally only, not in backend)
      final profile = UserProfile(
        name: _nameController.text.trim(),  // Stored locally only
        securityPassword: _passwordController.text,
        preferredLanguage: result['language']?.toString() ?? systemLanguage,
        userId: result['user_id'] as int?,
        hasSecurityPassword: true,
        securityPasswordSetAt: DateTime.now(),
        isVerified: true,
      );

      final saved = await UserProfileManager.saveProfile(profile);
      
      if (!saved) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving local information. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to ChatPage with initial message
      print('[OnboardingPage] Preparing to navigate to ChatPage');
      print('[OnboardingPage] Initial message: ${result['message']?.toString()}');
      
      if (!mounted) {
        print('[OnboardingPage] Widget not mounted, cannot navigate');
        return;
      }
      
      // Reset submitting state before navigation
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      
      // Navigate to ChatPage - MUST happen after successful save
      print('[OnboardingPage] Navigating to ChatPage...');
      print('[OnboardingPage] User ID: ${result['user_id']}');
      print('[OnboardingPage] Initial message: ${result['message']?.toString()}');
      
      if (!mounted) {
        print('[OnboardingPage] ERROR: Widget not mounted, cannot navigate');
        return;
      }
      
      // Ensure navigation happens - use pushReplacement to close onboarding page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            initialMessage: result['message']?.toString(),
          ),
        ),
      );
      
      print('[OnboardingPage] Navigation completed - OnboardingPage closed, ChatPage opened');
    } catch (e, stackTrace) {
      print('[OnboardingPage] ERROR in _submitForm: $e');
      print('[OnboardingPage] Stack trace: $stackTrace');
      
      if (mounted) {
        // Translate error message based on system language
        final systemLanguage = _getSystemLanguage();
        String errorMessage = 'Error: $e';
        
        if (systemLanguage == 'fa') {
          errorMessage = 'خطا در ثبت اطلاعات. لطفاً دوباره تلاش کنید.';
        } else if (systemLanguage == 'ar') {
          errorMessage = 'خطأ في تسجيل المعلومات. يرجى المحاولة مرة أخرى.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Reset submitting state on error
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
    print('[OnboardingPage] ========== _submitForm END ==========');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerWidth = screenSize.width * 0.9; // 90% of screen width
    // Fixed container height to prevent shrinking when keyboard opens
    final containerHeight = 320.0; // Fixed height to prevent background from shrinking

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite, // White background like ChatPage
      resizeToAvoidBottomInset: false, // Prevent background from shrinking when keyboard opens
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER (Sedi Logo) =================
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              child: SediHeader(
                isThinking: false,
                isAlert: false,
                size: 134.4, // Same size as ChatPage (20% smaller: 168 * 0.8 = 134.4)
              ),
            ),
            
            // ================= ONBOARDING FORM =================
            Expanded(
              child: Center(
                // Onboarding form - Fixed height container
                child: Container(
                  width: containerWidth,
                  height: containerHeight, // Fixed height
                  decoration: BoxDecoration(
                    color: AppTheme.metalGrey.withOpacity(0.3), // Grey transparent from theme
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
                          // Name input
                          _buildNameSection(),
                          const SizedBox(height: 12),
                          
                          // Password input
                          _buildPasswordSection(),
                          
                          // Spacer to push button to bottom
                          const Spacer(),
                          
                          // Submit button - positioned at bottom center
                          _buildSubmitButton(),
                          const SizedBox(height: 8), // Space at bottom to ensure button is inside
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
        // Label above the input field
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
        // Input field
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryBlack, // Black border
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.metalGrey.withOpacity(0.2), // Grey transparent inside from theme
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: AppTheme.textPrimary.withOpacity(0.5), // 50% lighter hint text
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(
                color: AppTheme.textPrimary, // Full color for typed text (black)
                fontSize: 16,
              ),
              textDirection: TextDirection.ltr,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
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
        // Label above the input field
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
        // Input field
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryBlack, // Black border
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.metalGrey.withOpacity(0.2), // Grey transparent inside from theme
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
            ),
            child: TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Enter security password',
                hintStyle: TextStyle(
                  color: AppTheme.textPrimary.withOpacity(0.5), // 50% lighter hint text
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _isPasswordValid
                    ? Icon(Icons.check_circle, color: AppTheme.pistachioGreen, size: 20)
                    : null,
              ),
              style: const TextStyle(
                color: AppTheme.textPrimary, // Full color for typed text (black)
                fontSize: 16,
              ),
              obscureText: true,
              textDirection: TextDirection.ltr,
              // Removed inputFormatters to allow any characters
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
    // 20% larger: 48 * 1.2 = 57.6 ≈ 58
    const buttonSize = 58.0;
    // Icon size: 28 * 1.2 = 33.6 ≈ 34
    const iconSize = 34.0;
    
    final isEnabled = _isFormValid && !_isSubmitting;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Ensure taps are captured
      onTap: isEnabled ? () {
        print('[OnboardingPage] ========== Submit button TAPPED ==========');
        print('[OnboardingPage] Form valid: $_isFormValid');
        print('[OnboardingPage] Submitting: $_isSubmitting');
        print('[OnboardingPage] Name: "${_nameController.text.trim()}"');
        print('[OnboardingPage] Password: "${_passwordController.text}" (length: ${_passwordController.text.length})');
        print('[OnboardingPage] Password valid: $_isPasswordValid');
        print('[OnboardingPage] Calling _submitForm...');
        _submitForm();
      } : () {
        // Show feedback when button is disabled
        print('[OnboardingPage] Button disabled - Form valid: $_isFormValid, Submitting: $_isSubmitting');
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.primaryBlack // Black when valid (form is filled)
              : AppTheme.metalGrey, // Grey when invalid or submitting
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
                color: AppTheme.backgroundWhite, // Always white checkmark
                size: iconSize,
              ),
      ),
    );
  }
}

