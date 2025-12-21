import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'sedi_ring_anim.dart';

/// Header widget:
/// - shows big Sedi logo in center (static)
/// - shows pistachio ring around it (animated when isThinking/isAlert)
class SediHeader extends StatelessWidget {
  final bool isThinking;
  final bool isAlert;
  final double size;

  const SediHeader({
    super.key,
    required this.isThinking,
    required this.isAlert,
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) {
    final active = isThinking || isAlert;

    // ring thickness accounted in ring widget
    final ringThickness = 2.5;
    // Keep some padding so logo doesn't touch ring visually
    final logoContainerSize = size - (ringThickness * 2) - 14;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring only (animated)
          SediRingAnim(
            active: active,
            size: size,
            thickness: ringThickness,
          ),

          // Logo container (static)
          Container(
            width: logoContainerSize,
            height: logoContainerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/sedi_logo_1024.png',
                fit: BoxFit.contain,
                width: logoContainerSize * 0.72,
                height: logoContainerSize * 0.72,
                errorBuilder: (_, __, ___) {
                  return Text(
                    'Sedi.',
                    style: TextStyle(
                      fontSize: logoContainerSize * 0.24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pistachioGreen,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
