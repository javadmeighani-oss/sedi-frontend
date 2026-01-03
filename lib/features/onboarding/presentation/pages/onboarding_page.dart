import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../core/config/app_config.dart';
import '../../../chat/chat_service.dart';
import '../../../chat/presentation/pages/chat_page.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _passwordController.addListener(_validatePassword);
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
    // - At least 6 characters
    // - Only uppercase Latin letters (A-Z) and English numbers (0-9)
    final hasMinLength = password.length >= 6;
    final hasOnlyValidChars = password.contains(RegExp(r'^[A-Z0-9]+$'));
    final hasLetters = password.contains(RegExp(r'[A-Z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    
    setState(() {
      _isPasswordValid = hasMinLength && hasOnlyValidChars && hasLetters && hasNumbers;
      _validateForm();
    });
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().isNotEmpty && 
                     _nameController.text.trim().length >= 2 &&
                     _isPasswordValid;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final chatService = ChatService();
      
      // Get system language
      final systemLanguage = _getSystemLanguage();
      
      // Setup onboarding with backend
      final result = await chatService.setupOnboarding(
        _nameController.text.trim(),
        _passwordController.text,
        systemLanguage,
      );

      if (result['user_id'] == null && !AppConfig.useLocalMode) {
        // Backend error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Error registering information. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Save user profile locally
      final profile = UserProfile(
        name: result['name']?.toString() ?? _nameController.text.trim(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving local information. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to chat page with initial message
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              initialMessage: result['message']?.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerWidth = screenSize.width * 0.9; // 90% of screen width
    // 20% more height: 0.25 * 1.2 = 0.3 (30% of screen height)
    final containerHeight = screenSize.height * 0.3;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite, // White background to prevent black overlay from showing through
      body: Center(
        // Onboarding form - Small container (30% of screen height)
        child: Container(
          width: containerWidth,
          constraints: BoxConstraints(
            maxHeight: containerHeight,
            minHeight: 240, // Minimum height for small screens (200 * 1.2)
          ),
          decoration: BoxDecoration(
            color: AppTheme.metalGrey.withOpacity(0.3), // Grey transparent from theme
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name input
                  _buildNameSection(),
                  const SizedBox(height: 12),
                  
                  // Password input
                  _buildPasswordSection(),
                  const SizedBox(height: 16),
                  
                  // Submit button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
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
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: AppTheme.textPrimary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'Security password (minimum 6 characters, uppercase Latin letters and numbers)',
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
                hintStyle: const TextStyle(color: AppTheme.textPrimary),
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), // Only uppercase letters and numbers
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter security password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return 'Password must contain uppercase letters';
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  return 'Password must contain numbers';
                }
                if (!value.contains(RegExp(r'^[A-Z0-9]+$'))) {
                  return 'Password must only contain uppercase letters and numbers';
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
    
    return Center(
      child: GestureDetector(
        onTap: _isFormValid && !_isSubmitting ? _submitForm : null,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: _isFormValid && !_isSubmitting
                ? AppTheme.primaryBlack // Black when valid
                : AppTheme.metalGrey, // Grey when invalid or submitting (from theme)
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
                  color: _isFormValid
                      ? AppTheme.backgroundWhite // White checkmark when valid
                      : AppTheme.metalGrey.withOpacity(0.5),
                  size: iconSize,
                ),
        ),
      ),
    );
  }
}

