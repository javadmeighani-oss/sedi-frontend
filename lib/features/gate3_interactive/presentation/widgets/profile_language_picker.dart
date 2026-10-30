import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../gate3_localization.dart';

/// The letter that stands for a language in the profile: ف / ع / A (no flags - Arabic spans many countries).
class SediLanguageGlyph {
  SediLanguageGlyph._();

  static String of(String? code) {
    switch ((code ?? '').toLowerCase()) {
      case 'fa':
        return 'ف';
      case 'ar':
        return 'ع';
      case 'en':
        return 'A';
      default:
        return '•';
    }
  }
}

/// A round liquid-glass badge with the language letter: a thin light ring, or the pistachio 3D sphere when selected.
class SediLanguageBadge extends StatelessWidget {
  final String? code;
  final double size;
  final bool selected;

  const SediLanguageBadge({
    super.key,
    required this.code,
    this.size = 44,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: selected ? SediGlass.pistachioSphere() : SediGlass.lightRing(),
      child: Text(
        SediLanguageGlyph.of(code),
        style: TextStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w800,
          height: 1.0,
          color: selected ? SediGlass.inkDeep : SediGlass.ink,
        ),
      ),
    );
  }
}

/// The profile language chooser: one frosted glass panel, three glass rows, a letter badge each, the current one lit.
class ProfileLanguagePicker {
  ProfileLanguagePicker._();

  /// (code, the language in its own script)
  static const List<(String, String)> options = [
    ('fa', 'فارسی'),
    ('ar', 'العربية'),
    ('en', 'English'),
  ];

  /// Returns the chosen code, or null when the panel is dismissed.
  static Future<String?> show(BuildContext context, {required String current}) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x2E243008),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => _LanguagePanel(current: current.toLowerCase()),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _LanguagePanel extends StatelessWidget {
  final String current;

  const _LanguagePanel({required this.current});

  @override
  Widget build(BuildContext context) {
    final locale = SediLocaleController.instance;
    final l10n = Gate3Localization(locale.languageCode);
    const radius = BorderRadius.all(Radius.circular(34));
    return Directionality(
      textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SediGlass.blur(
              radius: radius,
              sigma: 26,
              child: DecoratedBox(
                decoration: SediGlass.card(radius, strong: true),
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.profileLanguageChooseTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: SediGlass.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final option in ProfileLanguagePicker.options) ...[
                          _LanguageRow(
                            code: option.$1,
                            name: option.$2,
                            selected: option.$1 == current,
                          ),
                          if (option != ProfileLanguagePicker.options.last)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String code;
  final String name;
  final bool selected;

  const _LanguageRow({
    required this.code,
    required this.name,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      onTap: () => Navigator.of(context).pop(code),
      child: InkWell(
        borderRadius: radius,
        onTap: () => Navigator.of(context).pop(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 68,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? [Colors.white.withOpacity(0.82), Colors.white.withOpacity(0.38)]
                  : [Colors.white.withOpacity(0.52), Colors.white.withOpacity(0.16)],
            ),
            border: Border.all(
              color: selected ? const Color(0xFFA9C648) : Colors.white.withOpacity(0.72),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF48551F).withOpacity(selected ? 0.18 : 0.10),
                blurRadius: selected ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SediLanguageBadge(code: code, size: 44, selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: SediGlass.ink,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Container(
                        key: const ValueKey('picked'),
                        width: 28,
                        height: 28,
                        decoration: SediGlass.pistachioSphere(),
                        child: const Icon(Icons.check_rounded, size: 18, color: SediGlass.inkDeep),
                      )
                    : Container(
                        key: const ValueKey('free'),
                        width: 24,
                        height: 24,
                        decoration: SediGlass.lightRing(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
