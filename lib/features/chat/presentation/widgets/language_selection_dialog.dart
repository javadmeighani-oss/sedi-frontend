import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Dialog for language selection
class LanguageSelectionDialog extends StatelessWidget {
  final Function(String) onLanguageSelected;

  const LanguageSelectionDialog({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Select Language / انتخاب زبان / اختر اللغة',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            context,
            'English',
            'en',
            '🇬🇧',
            'Continue in English',
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            context,
            'فارسی',
            'fa',
            '🇮🇷',
            'ادامه به فارسی',
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            context,
            'العربية',
            'ar',
            '🇸🇦',
            'المتابعة بالعربية',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String code,
    String flag,
    String subtitle,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onLanguageSelected(code);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.iconInactive,
            ),
          ],
        ),
      ),
    );
  }
}
