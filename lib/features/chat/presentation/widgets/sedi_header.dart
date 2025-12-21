import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'sedi_ring_anim.dart';

/// ============================================
/// SediHeader - هدر صدی
/// ============================================
/// 
/// CONTRACT:
/// - لوگو بزرگ در مرکز (ثابت)
/// - حلقه سبز پسته‌ای دور لوگو
/// - فقط حلقه animate شود (heartbeat)
/// - انیمیشن فقط وقتی isThinking == true یا isAlert == true
/// ============================================
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
    final isActive = isThinking || isAlert;

    // Logo size as ratio of header size (safe & responsive)
    final logoSize = size * 0.78;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated ring (logic isolated inside ring widget)
          SediRingAnim(
            active: isActive,
            size: size,
          ),

          // Static logo
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundWhite,
              boxShadow: AppTheme.softShadow,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/sedi_logo_1024.png',
                fit: BoxFit.contain,
                width: logoSize * 0.7,
                height: logoSize * 0.7,
                errorBuilder: (_, __, ___) {
                  return Text(
                    'Sedi.',
                    style: TextStyle(
                      fontSize: logoSize * 0.24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlack,
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
