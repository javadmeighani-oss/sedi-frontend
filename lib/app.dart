import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/locale/sedi_locale_controller.dart';
import 'core/locale/sedi_locale_registry.dart';
import 'core/navigation/app_navigator.dart';
import 'core/notifications/notification_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/intro/presentation/pages/intro_page.dart';

class SediApp extends StatefulWidget {
  const SediApp({super.key});

  /// Single root localization authority — used by production MaterialApp and
  /// production-root regression tests (do not fork feature-local delegates).
  static const List<LocalizationsDelegate<dynamic>> localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  State<SediApp> createState() => _SediAppState();
}

class _SediAppState extends State<SediApp> with WidgetsBindingObserver {
  final SediLocaleController _locale = SediLocaleController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale.addListener(_onLocaleChanged);
    // Locale is resolved in main() before runApp to avoid an async EN flash.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationBootstrap.onAppResumed();
    }
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final descriptor = _locale.current;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: descriptor.locale,
      supportedLocales: SediLocaleRegistry.supportedLocales,
      localizationsDelegates: SediApp.localizationDelegates,

      // ===============================
      // Theme (Single Source of Truth)
      // ===============================
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.background,
        fontFamily: 'default',
        textTheme: const TextTheme(
          bodyMedium: AppTheme.bodyPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppTheme.iconInactive,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.background,
          elevation: 0,
          iconTheme: IconThemeData(
            color: AppTheme.primary,
          ),
          titleTextStyle: AppTheme.titleMedium,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: descriptor.textDirection,
        child: child ?? const SizedBox.shrink(),
      ),

      // ===============================
      // Gate 1 entry (see AppGateRouter / SessionGateResolver)
      // ===============================
      home: const IntroPage(),
    );
  }
}
