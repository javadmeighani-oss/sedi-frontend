import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';

/// Shared presentation surface for A3 destinations reused by Lifestyle,
/// Gadgets, Notifications, and Profile. Pure UI — no API or authority.
class A3DestinationSurface {
  A3DestinationSurface._();

  static const Color canvas = SediPalette.shell100;

  /// Minimal look (D-078): flat cards, hairline border, no shadow.
  static const List<BoxShadow> cardShadow = <BoxShadow>[];

  static Color get hairline => AppTheme.gate2BorderSubtle.withOpacity(0.55);

  static BoxDecoration cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: AppTheme.gate2CardWhite,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(
        color: borderColor ?? hairline,
        width: 0.8,
      ),
      boxShadow: cardShadow,
    );
  }

  /// Formats an ISO date or timestamp for display.
  /// Date-only values keep their calendar date. Timezone-bearing values
  /// convert with [DateTime.toLocal]. Unparseable values are unchanged.
  static String formatIsoTimestamp(String? raw, String languageCode) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final s = raw.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      return CalendarDateMath.formatIsoForLanguage(s, languageCode);
    }
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return s;
    final local = parsed.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final date = CalendarDateMath.formatIsoForLanguage('$y-$mo-$d', languageCode);
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$date  $hh:$mm';
  }
}

class A3DestinationCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const A3DestinationCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
  });

  BoxDecoration _decoration() {
    final bg = backgroundColor ?? AppTheme.gate2CardWhite;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(
        color: borderColor ?? A3DestinationSurface.hairline,
        width: 0.8,
      ),
      boxShadow: A3DestinationSurface.cardShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    final bg = backgroundColor ?? AppTheme.gate2CardWhite;
    if (onTap == null && onLongPress == null) {
      return DecoratedBox(
        decoration: _decoration(),
        child: body,
      );
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          decoration: _decoration(),
          child: body,
        ),
      ),
    );
  }
}

class A3DestinationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const A3DestinationChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SediPalette.pistachio500.withOpacity(0.24)
          : AppTheme.gate2CardWhite,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? SediPalette.pistachio700.withOpacity(0.55)
                  : A3DestinationSurface.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? SediPalette.pistachio900
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class A3DestinationFact extends StatelessWidget {
  final String label;
  final String value;
  final TextDirection? valueDirection;
  final Color? valueColor;

  const A3DestinationFact({
    super.key,
    required this.label,
    required this.value,
    this.valueDirection,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: valueDirection ?? Directionality.of(context),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
