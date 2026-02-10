/// Lifestyle screen: context summary + manual update. Apple-like; RTL support.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../data/dto/lifestyle_context_response.dart';
import '../../logic/lifestyle_controller.dart';
import '../../logic/lifestyle_validation.dart';

class LifestylePage extends StatefulWidget {
  const LifestylePage({super.key});

  @override
  State<LifestylePage> createState() => _LifestylePageState();
}

class _LifestylePageState extends State<LifestylePage> {
  final LifestyleController _controller = LifestyleController();
  final _sleepController = TextEditingController();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _stressController = TextEditingController();
  bool _loading = true;
  String _language = 'en';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _load();
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _stressController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final lang = await UserPreferences.getUserLanguage();
    if (mounted) setState(() => _language = lang);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _controller.loadContext();
    if (mounted) setState(() => _loading = false);
  }

  bool get _isRtl => _language == 'fa' || _language == 'ar';

  String? get _sleepError {
    final s = _sleepController.text.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    final v = double.tryParse(s);
    if (v == null) return 'Out of range';
    return validateSleepHours(v) != null ? 'Out of range' : null;
  }

  String? get _stepsError {
    final s = _stepsController.text.trim();
    if (s.isEmpty) return null;
    final v = int.tryParse(s);
    if (v == null) return 'Out of range';
    return validateSteps(v) != null ? 'Out of range' : null;
  }

  String? get _caloriesError {
    final s = _caloriesController.text.trim();
    if (s.isEmpty) return null;
    final v = int.tryParse(s);
    if (v == null) return 'Out of range';
    return validateCalories(v) != null ? 'Out of range' : null;
  }

  String? get _stressError {
    final s = _stressController.text.trim();
    if (s.isEmpty) return null;
    final v = int.tryParse(s);
    if (v == null) return 'Out of range';
    return validateStressLevel(v) != null ? 'Out of range' : null;
  }

  bool get _canSubmit =>
      _sleepError == null && _stepsError == null && _caloriesError == null && _stressError == null &&
      !_submitting && !_controller.isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final sleep = double.tryParse(_sleepController.text.trim().replaceAll(',', '.'));
    final steps = int.tryParse(_stepsController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());
    final stress = int.tryParse(_stressController.text.trim());

    setState(() => _submitting = true);
    try {
      final ok = await _controller.submitUpdate(
        sleepHours: sleep,
        steps: steps,
        calories: calories,
        stressLevel: stress,
      );
      if (!mounted) return;
      if (ok) {
        _showSnackBar('Lifestyle updated');
        _sleepController.clear();
        _stepsController.clear();
        _caloriesController.clear();
        _stressController.clear();
        _load();
      } else {
        _showSnackBar(_controller.errorMessage ?? 'Failed to update', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.pistachioGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _controller.parsedContext;
    final hasContext = ctx != null &&
        (ctx.sleepHours != null || ctx.steps != null || ctx.calories != null || ctx.stressLevel != null);

    Widget body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Context section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Context',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.pistachioGreen)),
          )
        else if (!hasContext)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'No lifestyle context yet.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          )
        else
          _buildContextRows(ctx),
        const SizedBox(height: 24),
        // Update form
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Update',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildField(
          controller: _sleepController,
          label: 'Sleep hours (0–24)',
          hint: 'e.g. 7.5',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          errorText: _sleepError,
        ),
        _buildField(
          controller: _stepsController,
          label: 'Steps (0–100000)',
          hint: 'e.g. 5000',
          keyboard: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _stepsError,
        ),
        _buildField(
          controller: _caloriesController,
          label: 'Calories (0–20000)',
          hint: 'e.g. 2000',
          keyboard: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _caloriesError,
        ),
        _buildField(
          controller: _stressController,
          label: 'Stress level (0–10)',
          hint: 'e.g. 2',
          keyboard: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _stressError,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.pistachioGreen,
              foregroundColor: AppTheme.backgroundWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            child: (_submitting || _controller.isSubmitting)
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundWhite),
                  )
                : const Text('Update lifestyle'),
          ),
        ),
      ],
    );

    Widget page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Lifestyle'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryBlack,
      ),
      body: body,
    );

    if (_isRtl) {
      page = Directionality(
        textDirection: TextDirection.rtl,
        child: page,
      );
    }
    return page;
  }

  Widget _buildContextRows(LifestyleContextResponse ctx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderInactive.withOpacity(0.5), width: 0.5)),
      ),
      child: Column(
        children: [
          if (ctx.sleepHours != null)
            _contextRow('Sleep hours', '${ctx.sleepHours!.toStringAsFixed(1)} h'),
          if (ctx.steps != null) _contextRow('Steps', '${ctx.steps}'),
          if (ctx.calories != null) _contextRow('Calories', '${ctx.calories}'),
          if (ctx.stressLevel != null) _contextRow('Stress level', '${ctx.stressLevel}'),
        ],
      ),
    );
  }

  Widget _contextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboard,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: const BorderSide(color: AppTheme.borderInactive),
          ),
        ),
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        textDirection: TextDirection.ltr,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
