import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/models/user_profile.dart';
import '../../../chat/chat_service.dart';

/// ============================================
/// UserVerificationPage - صفحه تایید کاربری
/// ============================================
/// 
/// RESPONSIBILITY:
/// - دریافت زبان، نام و رمز از کاربر
/// - طراحی: کادر 1/4 صفحه، رنگ خاکستری متال ترنسپرنت
/// - سه کادر مستطیلی با خطوط مشکی و داخل خاکستری
/// - آیکن تایید که بعد از پر شدن کادرها فعال می‌شود
/// ============================================

class UserVerificationPage extends StatefulWidget {
  const UserVerificationPage({super.key});

  @override
  State<UserVerificationPage> createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  String _selectedLanguage = 'fa'; // Default: Persian
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Validation state
  bool _isPasswordValid = false;
  bool _isFormValid = false;
  bool _isSubmitting = false;

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
      
      // Setup onboarding with backend (name no longer sent to backend)
      final result = await chatService.setupOnboarding(
        _passwordController.text,
        _selectedLanguage,
      );

      if (result['user_id'] == null) {
        // Backend error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'خطا در ثبت اطلاعات. لطفاً دوباره تلاش کنید.'),
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
        preferredLanguage: result['language']?.toString() ?? _selectedLanguage,
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
              content: Text('خطا در ذخیره اطلاعات محلی. لطفاً دوباره تلاش کنید.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Close page after successful submission
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: $e'),
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
    final containerHeight = screenSize.height * 0.25; // 25% of screen height (1/4)

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent background overlay (tap to dismiss)
          GestureDetector(
            onTap: () {
              // Optional: Allow tap outside to dismiss
              // Navigator.of(context).pop();
            },
            child: Container(
              color: AppTheme.primaryBlack.withOpacity(0.3),
            ),
          ),
          // Main verification form container
          Center(
            child: Container(
              width: containerWidth,
              constraints: BoxConstraints(
                maxHeight: containerHeight,
                minHeight: 200, // Minimum height for small screens
              ),
              decoration: BoxDecoration(
                color: AppTheme.metalGrey.withOpacity(0.3), // Grey transparent
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Language selection
                      _buildLanguageSection(),
                      const SizedBox(height: 12),
                      
                      // Name input
                      _buildNameSection(),
                      const SizedBox(height: 12),
                      
                      // Password input
                      _buildPasswordSection(),
                      const SizedBox(height: 16),
                      
                      // Submit button (check icon)
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlack, // Black border
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.metalGrey.withOpacity(0.2), // Grey transparent inside
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('فارسی'),
                value: 'fa',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('العربية'),
                value: 'ar',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlack, // Black border
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.metalGrey.withOpacity(0.2), // Grey transparent inside
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
        ),
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'نام خود را وارد کنید',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textDirection: TextDirection.rtl,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'لطفاً نام خود را وارد کنید';
            }
            if (value.trim().length < 2) {
              return 'نام باید حداقل 2 کاراکتر باشد';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryBlack, // Black border
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.metalGrey.withOpacity(0.2), // Grey transparent inside
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1.5),
        ),
        child: TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'رمز امنیتی را وارد کنید',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _isPasswordValid
                ? Icon(Icons.check_circle, color: AppTheme.pistachioGreen, size: 20)
                : null,
          ),
          obscureText: true,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), // Only uppercase letters and numbers
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً رمز امنیتی را وارد کنید';
            }
            if (value.length < 6) {
              return 'رمز باید حداقل 6 کاراکتر باشد';
            }
            if (!value.contains(RegExp(r'[A-Z]'))) {
              return 'رمز باید شامل حروف لاتین بزرگ باشد';
            }
            if (!value.contains(RegExp(r'[0-9]'))) {
              return 'رمز باید شامل اعداد انگلیسی باشد';
            }
            if (!value.contains(RegExp(r'^[A-Z0-9]+$'))) {
              return 'رمز باید فقط شامل حروف لاتین بزرگ و اعداد انگلیسی باشد';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isFormValid && !_isSubmitting ? _submitForm : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isFormValid && !_isSubmitting
              ? AppTheme.primaryBlack // Black when valid
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
                color: _isFormValid
                    ? AppTheme.backgroundWhite
                    : AppTheme.metalGrey.withOpacity(0.5),
                size: 28,
              ),
      ),
    );
  }
}

/// Helper function to show user verification page as a dialog
Future<void> showUserVerificationDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent, // We handle background in the page itself
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return const UserVerificationPage();
    },
  );
}

