import 'package:flutter/material.dart';

import '../../features/auth_otp/presentation/pages/otp_login_page.dart';
import '../../features/gate3_interactive/presentation/pages/gate3_interactive_page.dart';
import '../../features/intro/presentation/pages/intro_page.dart';
import 'app_gate.dart';

/// Central navigation for the 3-gate frontend architecture.
///
/// Use [replaceWithGate] / [goToLogin] / [goToHeart] instead of scattering
/// `Navigator.pushReplacement` calls across feature pages.
class AppGateRouter {
  AppGateRouter._();

  static Widget buildGatePage(
    SediAppGate gate, {
    String? initialMessage,
    bool fromNotification = false,
    int? notificationId,
  }) {
    switch (gate) {
      case SediAppGate.splash:
        return const IntroPage();
      case SediAppGate.login:
        return const OtpLoginPage();
      case SediAppGate.heart:
        return Gate3InteractivePage(
          initialMessage: initialMessage,
          fromNotification: fromNotification,
          notificationId: notificationId,
        );
    }
  }

  /// Replace the entire navigation stack with [gate].
  static void replaceWithGate(
    BuildContext context,
    SediAppGate gate, {
    String? initialMessage,
    bool fromNotification = false,
    int? notificationId,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => buildGatePage(
          gate,
          initialMessage: initialMessage,
          fromNotification: fromNotification,
          notificationId: notificationId,
        ),
      ),
      (_) => false,
    );
  }

  static void goToLogin(BuildContext context) {
    replaceWithGate(context, SediAppGate.login);
  }

  static void goToHeart(
    BuildContext context, {
    String? initialMessage,
    bool fromNotification = false,
    int? notificationId,
  }) {
    replaceWithGate(
      context,
      SediAppGate.heart,
      initialMessage: initialMessage,
      fromNotification: fromNotification,
      notificationId: notificationId,
    );
  }

  /// A1 -> A2/A3 slide. Shortened from 600 ms so the hand-over after the logo stops feels immediate.
  static const Duration kSplashToGateTransition = Duration(milliseconds: 300);

  /// Splash-only cube transition into Gate 2 or Gate 3.
  static void transitionFromSplash(
    BuildContext context,
    SediAppGate gate, {
    required Widget splashPage,
    String? initialMessage,
  }) {
    assert(gate != SediAppGate.splash);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => buildGatePage(
          gate,
          initialMessage: initialMessage,
        ),
        transitionDuration: kSplashToGateTransition,
        reverseTransitionDuration: kSplashToGateTransition,
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
                  child: splashPage,
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
      ),
    );
  }
}
