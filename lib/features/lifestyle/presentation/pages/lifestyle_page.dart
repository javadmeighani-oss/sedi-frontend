import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../core/widgets/app_states/app_empty_state.dart';
import '../../../../core/widgets/app_states/app_error_state.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../data/dto/lifestyle/lifestyle_entry_dto.dart';
import '../../../../data/dto/lifestyle/lifestyle_update_request_dto.dart';
import '../../../../data/models/lifestyle_state.dart';
import '../../../../services/lifestyle/lifestyle_service.dart';
import '../../../auth_otp/presentation/pages/otp_login_page.dart';

class LifestylePage extends StatefulWidget {
  const LifestylePage({super.key});

  @override
  State<LifestylePage> createState() => _LifestylePageState();
}

class _LifestylePageState extends State<LifestylePage> {
  final LifestyleService _service = LifestyleService();
  LifestyleState _state = const LifestyleState();
  bool _loading = true;
  String? _error;
  int? _userId;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final profile = await UserProfileManager.loadProfile();
    _lang =
        profile.preferredLanguage.isNotEmpty ? profile.preferredLanguage : 'en';
    _userId = await UserIdentityService.resolveUserId();
    if (_userId == null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OtpLoginPage()),
      );
      return;
    }
    await _load();
  }

  bool get _isRtl => _lang == 'fa' || _lang == 'ar';

  Future<void> _load() async {
    if (_userId == null) {
      setState(() {
        _loading = false;
        _error = null;
        _state = const LifestyleState();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.getLifestyle(userId: _userId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _state = res.data ?? const LifestyleState();
      } else {
        _error = res.errorMessage;
      }
    });
  }

  Future<void> _saveOptimistic(
      List<LifestyleEntryDto> entries, LifestyleState optimistic) async {
    if (_userId == null) return;
    final previous = _state;
    setState(() {
      _state = optimistic;
    });

    final req = LifestyleUpdateRequestDto(userId: _userId!, entries: entries);
    final res = await _service.updateLifestyle(userId: _userId!, req: req);
    if (!mounted) return;
    if (!res.ok) {
      setState(() {
        _state = previous;
      });
      _showMessage(res.errorMessage);
      return;
    }
    _showMessage('Saved');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Lifestyle'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryBlack,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBlack,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: page,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListView(
        children: [
          SizedBox(height: 120),
          AppLoadingState(label: 'Loading lifestyle...'),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          AppErrorState(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_state.isEmpty) {
      return ListView(
        children: [
          _todayChips(),
          const SizedBox(height: 120),
          const AppEmptyState(
            title: 'Set your first lifestyle baseline',
            subtitle: 'Add your sleep, activity, water, and mood today.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _todayChips(),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Sleep',
          subtitle:
              '${_state.sleepDurationHours?.toStringAsFixed(1) ?? '--'} h',
          onTap: _editSleep,
        ),
        _sectionCard(
          title: 'Activity',
          subtitle:
              '${_state.stepsCount ?? '--'} steps • ${_state.exerciseMinutes ?? '--'} min',
          onTap: _editActivity,
        ),
        _sectionCard(
          title: 'Water',
          subtitle: '${_state.hydrationMl?.toStringAsFixed(0) ?? '--'} ml',
          onTap: _editWater,
        ),
        _sectionCard(
          title: 'Mood / Stress',
          subtitle: '${_state.mood ?? '--'} • ${_state.stressLevel ?? '--'}',
          onTap: _editMoodStress,
        ),
      ],
    );
  }

  Widget _todayChips() {
    final chips = <String>[
      if (_state.sleepDurationHours != null)
        '${_state.sleepDurationHours!.toStringAsFixed(1)}h sleep',
      if (_state.stepsCount != null) '${_state.stepsCount} steps',
      if (_state.hydrationMl != null)
        '${_state.hydrationMl!.toStringAsFixed(0)}ml water',
      if (_state.stressLevel != null) 'stress ${_state.stressLevel}',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (text) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.borderInactive.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                text,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.borderInactive.withOpacity(0.3)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _editSleep() async {
    double sleep = _state.sleepDurationHours ?? 7.0;
    String quality = _state.sleepQuality ?? 'normal';
    await _editorSheet(
      title: 'Sleep',
      content: StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            children: [
              Row(
                children: [
                  const Text('Hours',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text(sleep.toStringAsFixed(1),
                      style: const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
              Slider(
                value: sleep.clamp(0, 14),
                min: 0,
                max: 14,
                divisions: 28,
                activeColor: AppTheme.primaryBlack,
                inactiveColor: AppTheme.borderInactive,
                onChanged: (v) => setLocal(() => sleep = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: quality),
                decoration: const InputDecoration(
                  labelText: 'Quality',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (v) => quality = v.trim(),
              ),
            ],
          );
        },
      ),
      onSave: () async {
        final optimistic = _state.copyWith(
          sleepDurationHours: sleep,
          sleepQuality: quality,
        );
        await _saveOptimistic(
          [
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'sleep_duration_hours', value: sleep),
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'sleep_quality', value: quality),
          ],
          optimistic,
        );
      },
    );
  }

  Future<void> _editActivity() async {
    int steps = _state.stepsCount ?? 4000;
    int minutes = _state.exerciseMinutes ?? 20;
    String level = _state.activityLevel ?? 'moderate';
    await _editorSheet(
      title: 'Activity',
      content: StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            children: [
              _stepper(
                label: 'Steps',
                value: '$steps',
                onMinus: () =>
                    setLocal(() => steps = (steps - 500).clamp(0, 100000)),
                onPlus: () =>
                    setLocal(() => steps = (steps + 500).clamp(0, 100000)),
              ),
              const SizedBox(height: 8),
              _stepper(
                label: 'Exercise minutes',
                value: '$minutes',
                onMinus: () =>
                    setLocal(() => minutes = (minutes - 5).clamp(0, 300)),
                onPlus: () =>
                    setLocal(() => minutes = (minutes + 5).clamp(0, 300)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: level),
                decoration: const InputDecoration(
                  labelText: 'Activity level',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (v) => level = v.trim(),
              ),
            ],
          );
        },
      ),
      onSave: () async {
        final optimistic = _state.copyWith(
          stepsCount: steps,
          exerciseMinutes: minutes,
          activityLevel: level,
        );
        await _saveOptimistic(
          [
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'steps_count', value: steps),
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'exercise_minutes', value: minutes),
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'activity_level', value: level),
          ],
          optimistic,
        );
      },
    );
  }

  Future<void> _editWater() async {
    double water = _state.hydrationMl ?? 1200;
    await _editorSheet(
      title: 'Water',
      content: StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            children: [
              Row(
                children: [
                  const Text('Hydration (ml)',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text(
                    water.toStringAsFixed(0),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Slider(
                value: water.clamp(0, 5000),
                min: 0,
                max: 5000,
                divisions: 50,
                activeColor: AppTheme.primaryBlack,
                inactiveColor: AppTheme.borderInactive,
                onChanged: (v) => setLocal(() => water = v),
              ),
            ],
          );
        },
      ),
      onSave: () async {
        final optimistic = _state.copyWith(hydrationMl: water);
        await _saveOptimistic(
          [
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'hydration_ml', value: water)
          ],
          optimistic,
        );
      },
    );
  }

  Future<void> _editMoodStress() async {
    String mood = _state.mood ?? 'neutral';
    String stress = _state.stressLevel ?? 'low';
    await _editorSheet(
      title: 'Mood / Stress',
      content: StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            children: [
              TextField(
                controller: TextEditingController(text: mood),
                decoration: const InputDecoration(
                  labelText: 'Mood',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (v) => mood = v.trim(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: stress),
                decoration: const InputDecoration(
                  labelText: 'Stress',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (v) => stress = v.trim(),
              ),
            ],
          );
        },
      ),
      onSave: () async {
        final optimistic = _state.copyWith(mood: mood, stressLevel: stress);
        await _saveOptimistic(
          [
            LifestyleEntryDto(domain: 'lifestyle', key: 'mood', value: mood),
            LifestyleEntryDto(
                domain: 'lifestyle', key: 'stress_level', value: stress),
          ],
          optimistic,
        );
      },
    );
  }

  Widget _stepper({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const Spacer(),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline,
              color: AppTheme.textSecondary),
        ),
        Text(value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline,
              color: AppTheme.primaryBlack),
        ),
      ],
    );
  }

  Future<void> _editorSheet({
    required String title,
    required Widget content,
    required Future<void> Function() onSave,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await onSave();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: AppTheme.backgroundWhite,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
