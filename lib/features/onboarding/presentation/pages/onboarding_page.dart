import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// - دریافت زبان، نام و رمز از کاربر
/// - طراحی: ترنسپرنت پایین، رنگ خاکستری
/// - سه کادر مستطیلی مشکی با داخل خاکستری ترنسپرنت
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
    // - Contains letters
    // - Contains numbers
    // - Contains at least one uppercase letter
    final hasMinLength = password.length >= 6;
    final hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    
    setState(() {
      _isPasswordValid = hasMinLength && hasLetters && hasNumbers && hasUppercase;
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
      
      // Setup onboarding with backend
      final result = await chatService.setupOnboarding(
        _nameController.text.trim(),
        _passwordController.text,
        _selectedLanguage,
      );

      if (result['user_id'] == null && !AppConfig.useLocalMode) {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background with transparency
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3), // Grey transparent
            ),
          ),
          // Onboarding form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Language selection
                      _buildLanguageSection(),
                      const SizedBox(height: 24),
                      
                      // Name input
                      _buildNameSection(),
                      const SizedBox(height: 24),
                      
                      // Password input
                      _buildPasswordSection(),
                      const SizedBox(height: 32),
                      
                      // Submit button
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            'زبان تعاملی',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Language selection box
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack, // Black box
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2), // Grey transparent inside
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            'نام کاربر',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Name input box
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack, // Black box
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2), // Grey transparent inside
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'نام خود را وارد کنید',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with requirements
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رمز امنیتی',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'حداقل 6 کاراکتر، شامل حروف، اعداد و یک حرف بزرگ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Password input box
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack, // Black box
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2), // Grey transparent inside
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
            ),
            child: TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'رمز امنیتی را وارد کنید',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: _isPasswordValid
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              obscureText: true,
              textDirection: TextDirection.ltr,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'لطفاً رمز امنیتی را وارد کنید';
                }
                if (value.length < 6) {
                  return 'رمز باید حداقل 6 کاراکتر باشد';
                }
                if (!value.contains(RegExp(r'[a-zA-Z]'))) {
                  return 'رمز باید شامل حروف باشد';
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  return 'رمز باید شامل اعداد باشد';
                }
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return 'رمز باید شامل حداقل یک حرف بزرگ باشد';
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
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _isFormValid && !_isSubmitting
            ? AppTheme.primaryBlack // Black when valid
            : Colors.grey, // Grey when invalid or submitting
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isFormValid && !_isSubmitting ? _submitForm : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.check,
                    color: _isFormValid ? Colors.white : Colors.grey.shade300,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}

