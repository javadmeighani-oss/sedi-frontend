/// Apple-like tile: label + value. Neutral surfaces, subtle divider. Numbers LTR for readability.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VitalValueTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const VitalValueTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final display = unit != null ? '$value $unit' : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderInactive.withOpacity(0.5), width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            display,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
