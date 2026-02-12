import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../core/utils/gender_guess.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../services/push/push_service.dart';
import '../../../chat/chat_service.dart';
import '../../../notification/logic/notification_sync.dart';

/// UserVerificationPage – username and language only (no password).
/// Saves guessed gender to profile (optional, not shown in UI).

class UserVerificationPage extends StatefulWidget {
  const UserVerificationPage({super.key});

  @override
  State<UserVerificationPage> createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedLanguage = 'fa';
  final _nameController = TextEditingController();

  bool _isFormValid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().length >= 2;
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
      final name = _nameController.text.trim();
      final chatService = ChatService();
      final result = await chatService.setupOnboarding(
        _selectedLanguage,
        name: name,
      );

      if (result['user_id'] == null) {
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

      final guessed = guessGender(name, _selectedLanguage);
      final profile = UserProfile(
        name: result['name']?.toString() ?? name,
        securityPassword: null,
        preferredLanguage: result['language']?.toString() ?? _selectedLanguage,
        userId: result['user_id'] as int?,
        guessedGender: guessedGenderToValue(guessed),
        hasSecurityPassword: false,
        securityPasswordSetAt: null,
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

      // Trigger notification sync once (new items may show as local notifications)
      NotificationSync.syncOnce();
      await tryRegisterStoredTokenAfterLogin();

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
                      _buildLanguageSection(),
                      const SizedBox(height: 12),
                      _buildNameSection(),
                      const SizedBox(height: 16),
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

