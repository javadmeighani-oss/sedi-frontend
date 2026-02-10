/// Vitals screen: last known vitals (from cache) + manual add form. Apple-like, RTL support.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../logic/vitals_cache.dart';
import '../../logic/vitals_controller.dart';
import '../widgets/vital_value_tile.dart';

/// Allow digits and at most one decimal point for temperature.
final RegExp _temperatureAllow = RegExp(r'^\d*\.?\d*$');
class _TemperatureInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (!_temperatureAllow.hasMatch(newValue.text)) return oldValue;
    final dotCount = newValue.text.split('.').length - 1;
    if (dotCount > 1) return oldValue;
    return newValue;
  }
}

class VitalsPage extends StatefulWidget {
  const VitalsPage({super.key});

  @override
  State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  final VitalsController _controller = VitalsController();
  bool _loadingCache = true;
  String _language = 'en';

  // Form
  final _hrController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _tempController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadData();
  }

  Future<void> _loadLanguage() async {
    final lang = await UserPreferences.getUserLanguage();
    if (mounted) setState(() => _language = lang);
  }

  /// Load cache first, then try server; update controller.lastVitals and lastSource. No error on failure.
  Future<void> _loadData() async {
    setState(() => _loadingCache = true);
    await _controller.load();
    if (mounted) setState(() => _loadingCache = false);
  }

  @override
  void dispose() {
    _hrController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    super.dispose();
  }

  bool get _isRtl => _language == 'fa' || _language == 'ar';

  String? get _hrError {
    final s = _hrController.text.trim();
    if (s.isEmpty) return 'Required';
    final v = int.tryParse(s);
    if (v == null) return 'Out of range';
    return validateHeartRate(v) != null ? 'Out of range' : null;
  }

  String? get _spo2Error {
    final s = _spo2Controller.text.trim();
    if (s.isEmpty) return null;
    final v = int.tryParse(s);
    if (v == null) return 'Out of range';
    return validateSpO2(v) != null ? 'Out of range' : null;
  }

  String? get _tempError {
    final s = _tempController.text.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    final v = double.tryParse(s);
    if (v == null) return 'Out of range';
    return validateTemperature(v) != null ? 'Out of range' : null;
  }

  bool get _canSubmit =>
      _hrError == null && _spo2Error == null && _tempError == null && !_submitting && !_controller.isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final hrText = _hrController.text.trim();
    final hr = int.tryParse(hrText);
    if (hr == null || _hrError != null) {
      _showSnackBar('Heart rate is required', isError: true);
      return;
    }
    final spo2 = int.tryParse(_spo2Controller.text.trim());
    final temp = double.tryParse(_tempController.text.trim().replaceAll(',', '.'));

    setState(() => _submitting = true);
    try {
      final (success, error) = await _controller.submit(heartRate: hr, spo2: spo2, temperature: temp);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Vitals saved');
        _hrController.clear();
        _spo2Controller.clear();
        _tempController.clear();
        _loadData();
      } else {
        _showSnackBar(error ?? 'Failed to save', isError: true);
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
    Widget body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Last recorded section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                'Last recorded',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _controller.lastSource == kSourceServer ? 'Source: Server' : 'Source: Local',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        if (_loadingCache)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.pistachioGreen)),
          )
        else if (_controller.lastVitals == null || (_controller.lastVitals!.heartRate == null && _controller.lastVitals!.spo2 == null && _controller.lastVitals!.temperature == null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'No vitals recorded yet.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          )
        else ...[
          if (_controller.lastVitals!.heartRate != null)
            VitalValueTile(label: 'Heart rate', value: _controller.lastVitals!.heartRate!.round().toString(), unit: 'bpm'),
          if (_controller.lastVitals!.spo2 != null)
            VitalValueTile(label: 'SpO2', value: _controller.lastVitals!.spo2!.round().toString(), unit: '%'),
          if (_controller.lastVitals!.temperature != null)
            VitalValueTile(label: 'Temperature', value: _controller.lastVitals!.temperature!.toStringAsFixed(1), unit: '°C'),
          if (_controller.lastVitals!.createdAt != null)
            VitalValueTile(
              label: 'Recorded',
              value: _formatDate(_controller.lastVitals!.createdAt!),
            ),
        ],
        // Trend section (7-day mini trend)
        _buildTrendSection(),
        const SizedBox(height: 24),
        // Manual add form
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Add vitals',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildField(
          controller: _hrController,
          label: 'Heart rate (required)',
          hint: '30–220 bpm',
          keyboard: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _hrError,
        ),
        _buildField(
          controller: _spo2Controller,
          label: 'SpO2 (optional)',
          hint: '50–100 %',
          keyboard: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _spo2Error,
        ),
        _buildField(
          controller: _tempController,
          label: 'Temperature (optional)',
          hint: '30–45 °C',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_TemperatureInputFormatter()],
          errorText: _tempError,
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
                : const Text('Save vitals'),
          ),
        ),
      ],
    );

    Widget page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Vitals'),
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

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTrendSection() {
    const padding = EdgeInsets.fromLTRB(16, 16, 16, 4);
    final history = _controller.recentHistory;
    final avgHr = _controller.avgHeartRate7d;
    final count = _controller.countRecords7d;
    final hasData = count > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(
            'Trend',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            border: Border(bottom: BorderSide(color: AppTheme.borderInactive.withOpacity(0.5), width: 0.5)),
          ),
          child: Row(
            children: [
              Text(
                '7-day average HR',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const Spacer(),
              Text(
                hasData && avgHr != null ? '$avgHr bpm' : '—',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: history.take(5).map((CachedVitals e) {
                final time = e.createdAt != null ? _formatDate(e.createdAt!) : '—';
                final hr = e.heartRate != null ? '${e.heartRate!.round()} bpm' : '—';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.borderInactive.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), textDirection: TextDirection.ltr),
                      const SizedBox(width: 6),
                      Text(hr, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textDirection: TextDirection.ltr),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
