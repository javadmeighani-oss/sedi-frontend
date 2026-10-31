import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_gate.dart';
import '../../../../core/ui/sedi_warmup.dart';
import '../../../../core/navigation/app_gate_router.dart';
import '../../../../core/navigation/session_gate_resolver.dart';
import '../../../../core/network/backend_availability.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../features/chat/state/a3_session_prefetch.dart';
import '../../../../services/push/push_service.dart';

/// A1 — Sedi platform intro shown on every app open ("Birth of Sedi").
///
/// Visual animation is independent of auth. Startup session work runs in
/// parallel and is applied only after the intro duration completes.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  /// Approved A1 intro duration (~3 seconds).
  static const Duration kIntroDuration = Duration(milliseconds: 3000);

  /// Delay between cold-start revalidation attempts while backend is unavailable.
  static const Duration kReconnectRetryDelay = Duration(seconds: 2);

  /// Canonical horizon / cosmic sunrise background asset.
  static const String kHorizonAsset =
      'assets/images/cosmic_sunrise_background.png';

  /// LATIN brand lock for A1 (never localized).
  static const String kBrandLatin = 'Sedi.';

  /// Normalized keyframes: t, centerY (fraction of H), brandWidth (fraction of W).
  /// centerX is always 0.50W.
  static const List<(double t, double cy, double bw)> kMotionKeyframes = [
    (0.00, 0.79, 0.05),
    (0.50, 0.52, 0.24),
    (1.00, 0.27, 0.52),
  ];

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _masterController;

  late final Future<SessionResolveResult> _sessionFuture;
  late final Future<bool> _healthFuture;

  @override
  void initState() {
    super.initState();

    _sessionFuture = SessionGateResolver.resolveColdStart();
    _healthFuture = BackendAvailability.probeHealthz();
    // The logo plays for three seconds anyway: as soon as the session is known to be valid, Sedi's opener is asked for,
    // so A3 does not open on an empty chat while the server prepares it.
    _sessionFuture.then((s) {
      if (s.isAuthenticated) {
        A3SessionPrefetch.start(language: SediLocaleController.instance.languageCode);
      }
    }, onError: (_) {});

    _masterController = AnimationController(
      vsync: this,
      duration: IntroPage.kIntroDuration,
    )..forward();

    // The logo plays for three seconds anyway: get A3's wordmark and fonts ready meanwhile (no pop-in later).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SediWarmup.run(context);
    });

    _awaitIntroThenRoute();
  }

  /// Deterministic piecewise-linear interpolation across the 3 keyframes.
  static (double cy, double bw) sampleMotion(double t) {
    final frames = IntroPage.kMotionKeyframes;
    final clamped = t.clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < frames.length - 1; i++) {
      final a = frames[i];
      final b = frames[i + 1];
      if (clamped <= b.$1 || i == frames.length - 2) {
        final span = (b.$1 - a.$1).clamp(1e-9, 1.0).toDouble();
        final u = ((clamped - a.$1) / span).clamp(0.0, 1.0).toDouble();
        return (
          a.$2 + (b.$2 - a.$2) * u,
          a.$3 + (b.$3 - a.$3) * u,
        );
      }
    }
    return (frames.last.$2, frames.last.$3);
  }

  Future<void> _awaitIntroThenRoute() async {
    await Future<void>.delayed(IntroPage.kIntroDuration);
    var session = await _sessionFuture;
    await _healthFuture;

    if (!mounted) return;

    while (session.stayOnStartup) {
      await Future<void>.delayed(IntroPage.kReconnectRetryDelay);
      if (!mounted) return;
      session = await SessionGateResolver.resolveColdStart();
      await BackendAvailability.probeHealthz();
    }

    if (!mounted) return;
    await _navigateToNextGate(session);
  }

  Future<void> _navigateToNextGate(SessionResolveResult session) async {
    if (session.stayOnStartup || session.nextGate == SediAppGate.splash) {
      return;
    }

    final nextGate = session.nextGate;

    if (nextGate == SediAppGate.heart) {
      // Javad 2026-10-31: A3 must not wait for the push-token round trip (FCM token + a server call, every app open):
      // it runs behind the chat. It is fail-open inside and retried at the next open when it did not finish.
      unawaited(tryRegisterStoredTokenAfterLogin());
    }

    if (!mounted) return;
    AppGateRouter.transitionFromSplash(
      context,
      nextGate,
      splashPage: build(context),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.introNightSky,
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, _) {
          final sample = sampleMotion(_masterController.value);
          final brandW = size.width * sample.$2;
          // Keep aspect for "Sedi." wordmark roughly 1025:317
          final brandH = brandW * (317 / 1025);
          final centerY = size.height * sample.$1;
          final left = size.width * 0.5 - brandW / 2;
          final top = centerY - brandH / 2;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  IntroPage.kHorizonAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0A0E14),
                            Color(0xFF1A2332),
                            Color(0xFF3D5A40),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: brandW,
                height: brandH,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    IntroPage.kBrandLatin,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppTheme.introLogoEmphasis,
                      fontWeight: FontWeight.w800,
                      fontSize: 120,
                      height: 1.0,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
