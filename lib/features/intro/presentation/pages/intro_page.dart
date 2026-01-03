import 'package:flutter/material.dart';

import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../../core/utils/user_profile_manager.dart';

/// ============================================
/// IntroPage - Pre-Welcome Screen
/// ============================================
///
/// RESPONSIBILITY:
/// - Full screen intro with cosmic sunrise background image
/// - Sedi logo in center with breathing animation
/// - Auto-transition to ChatPage after ~2 seconds
/// - Right-to-left 3D cube transition animation
///
/// TIMELINE:
/// 0.0s  IntroPage appears, background visible
/// 0.2s  Logo fades in + starts breathing
/// 1.4s  Breathing animation finishes
/// 2.0s  Automatic navigation to ChatPage starts
/// ============================================
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  // Final logo size: 20% larger than before (92 * 1.2 = 110.4)
  static const double _finalLogoSize = 110.4;
  static const double _initialLogoSize = 84.0; // Start smaller (70 * 1.2)

  late AnimationController _fadeInController;
  late AnimationController _scaleUpController;
  late AnimationController _breathingController;

  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleUpAnimation;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Fade in animation (starts at 0.2s, duration 300ms)
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.3, // 30% less transparent (30% more opacity from start)
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeInController,
        curve: Curves.easeOut,
      ),
    );

    // Scale up animation (from initial to final size, starts at 0.2s)
    _scaleUpController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleUpAnimation = Tween<double>(
      begin: _initialLogoSize / _finalLogoSize, // ~0.76
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scaleUpController,
        curve: Curves.easeOut,
      ),
    );

    // Breathing animation (0.96 → 1.00 → 0.96, one cycle only, 1200ms)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.96,
      end: 1.00,
    ).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeInController.forward();
        _scaleUpController.forward();
        // Breathing: one cycle (forward then reverse)
        _breathingController.forward().then((_) {
          if (mounted) {
            _breathingController.reverse();
          }
        });
      }
    });

    // Auto-transition to OnboardingPage or ChatPage after 2.0s
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _navigateToNextPage();
      }
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _scaleUpController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextPage() async {
    // Check if user has completed onboarding
    final profile = await UserProfileManager.loadProfile();
    final hasCompletedOnboarding = profile.name != null && 
                                    profile.name!.isNotEmpty &&
                                    profile.securityPassword != null &&
                                    profile.securityPassword!.isNotEmpty;
    
    if (hasCompletedOnboarding) {
      // User has completed onboarding, go to chat
      Navigator.of(context).pushReplacement(
        _createCubeTransitionRouteToChat(),
      );
    } else {
      // User needs to complete onboarding first
      Navigator.of(context).pushReplacement(
        _createCubeTransitionRouteToOnboarding(),
      );
    }
  }
  
  PageRouteBuilder _createCubeTransitionRouteToOnboarding() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const OnboardingPage();
      },
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 600),
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        final exitAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOutCubic,
        );
        return Stack(
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-1.0, 0.0),
              ).animate(exitAnimation),
              child: FadeTransition(
                opacity: exitAnimation,
                child: build(context),
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
  
  PageRouteBuilder _createCubeTransitionRouteToChat() {
    final introPageState = this;
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return ChatPage();
      },
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 600),
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        final exitAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOutCubic,
        );
        return Stack(
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-1.0, 0.0),
              ).animate(exitAnimation),
              child: FadeTransition(
                opacity: exitAnimation,
                child: Builder(
                  builder: (context) => introPageState.build(context),
                ),
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cosmic sunrise background image
          // NOTE: Add 'cosmic_sunrise_background.png' to assets/images/
          // Fallback gradient shown if image not found
          Positioned.fill(
            child: Image.asset(
              'assets/images/cosmic_sunrise_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback gradient (cosmic sunrise colors) if image not found
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A1A2E), // Deep space blue
                        Color(0xFF16213E), // Dark blue
                        Color(0xFF0F3460), // Midnight blue
                        Color(0xFF533483), // Purple
                        Color(0xFFE94560), // Deep pink-red
                        Color(0xFFFF6B6B), // Coral red
                        Color(0xFFFFA07A), // Light salmon
                        Color(0xFFFFD700), // Gold (sunrise)
                      ],
                      stops: [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
          // Logo with animations (positioned 30% higher)
          SafeArea(
            child: Center(
              child: Transform.translate(
                offset: Offset(
                    0,
                    -MediaQuery.of(context).size.height *
                        0.15), // 30% higher (15% up from center)
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _fadeInAnimation,
                    _scaleUpAnimation,
                    _breathingAnimation,
                  ]),
                  builder: (context, child) {
                    // Combined scale: scale up + breathing
                    final combinedScale =
                        _scaleUpAnimation.value * _breathingAnimation.value;

                    return Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Transform.scale(
                        scale: combinedScale,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/sedi_logo_1024.png',
                    width: _finalLogoSize,
                    height: _finalLogoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
