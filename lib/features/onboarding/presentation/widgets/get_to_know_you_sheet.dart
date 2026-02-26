import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/messages.dart';
import '../../../../core/config/app_config.dart';
import '../../../../data/repositories/user_knowledge_repository.dart';

/// Canonical goal keys (shared with onboarding).
const List<String> getToKnowYouGoalKeys = [
  'better_sleep',
  'less_stress',
  'reduce_pain',
  'more_energy',
  'weight_management',
  'healthy_habits',
];

/// Bottom sheet for "Get to know you" when user reaches Chat without completing onboarding.
/// Persists preferred_name, language_pref, goals locally and best-effort sync to PUT /user/knowledge.
class GetToKnowYouSheet extends StatefulWidget {
  final int? userId;
  final String? prefilledName;

  const GetToKnowYouSheet({super.key, this.userId, this.prefilledName});

  @override
  State<GetToKnowYouSheet> createState() => _GetToKnowYouSheetState();
}

class _GetToKnowYouSheetState extends State<GetToKnowYouSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String _languagePref = 'auto';
  final List<String> _selectedGoals = [];

  static String _systemLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final code = locale.languageCode.toLowerCase();
    if (code == 'fa' || code == 'ar') return code;
    return 'en';
  }

  String _goalLabel(String key) {
    final lang = _systemLanguage();
    switch (key) {
      case 'better_sleep': return AppMessages.getGoalBetterSleep(lang);
      case 'less_stress': return AppMessages.getGoalLessStress(lang);
      case 'reduce_pain': return AppMessages.getGoalReducePain(lang);
      case 'more_energy': return AppMessages.getGoalMoreEnergy(lang);
      case 'weight_management': return AppMessages.getGoalWeightManagement(lang);
      case 'healthy_habits': return AppMessages.getGoalHealthyHabits(lang);
      default: return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.prefilledName ?? '';
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final lang = await UserPreferences.getLanguagePref();
    final goals = await UserPreferences.getGoals();
    if (mounted) {
      setState(() {
        _languagePref = lang;
        _selectedGoals.clear();
        _selectedGoals.addAll(goals);
        if (widget.prefilledName != null && _nameController.text.isEmpty) {
          _nameController.text = widget.prefilledName!;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    await UserPreferences.savePreferredName(name);
    await UserPreferences.saveLanguagePref(_languagePref);
    await UserPreferences.saveGoals(List<String>.from(_selectedGoals));
    await UserPreferences.setGetToKnowYouCompleted(true);

    if (widget.userId != null && !AppConfig.useLocalMode) {
      final resolvedLang = _languagePref == 'auto' ? _systemLanguage() : _languagePref;
      final goalsJson = _selectedGoals.isEmpty ? null : jsonEncode(_selectedGoals);
      try {
        final repo = UserKnowledgeRepository();
        final resp = await repo.upsertKnowledge(
          userId: widget.userId!,
          displayName: name,
          language: resolvedLang,
          goalsJson: goalsJson,
        );
        if (!resp.ok) {
          debugPrint('[GetToKnowYouSheet] PUT /user/knowledge failed (best-effort): ${resp.errorMessage}');
        }
      } catch (e) {
        debugPrint('[GetToKnowYouSheet] PUT /user/knowledge exception: $e');
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _systemLanguage();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppMessages.getPreferredNameLabel(lang),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              Text(
                AppMessages.getLanguageLabel(lang),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _languagePref,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (v) => setState(() => _languagePref = v ?? 'auto'),
              ),
              const SizedBox(height: 16),
              Text(
                AppMessages.getGoalsLabel(lang),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: getToKnowYouGoalKeys.map((key) {
                  final selected = _selectedGoals.contains(key);
                  final atMax = _selectedGoals.length >= 3 && !selected;
                  return FilterChip(
                    label: Text(_goalLabel(key)),
                    selected: selected,
                    onSelected: atMax ? null : (v) {
                      setState(() {
                        if (v) {
                          if (_selectedGoals.length < 3) _selectedGoals.add(key);
                        } else {
                          _selectedGoals.remove(key);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryBlack.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryBlack,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: AppTheme.backgroundWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundWhite),
                      )
                    : const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
