import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/user_profile_manager.dart';
import 'features/intro/presentation/pages/intro_page.dart';

class SediApp extends StatefulWidget {
  const SediApp({super.key});

  @override
  State<SediApp> createState() => _SediAppState();
}

class _SediAppState extends State<SediApp> {
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _loadDirectionality();
  }

  Future<void> _loadDirectionality() async {
    final profile = await UserProfileManager.loadProfile();
    final lang = profile.preferredLanguage.toLowerCase();
    if (!mounted) return;
    setState(() {
      _textDirection = (lang == 'fa' || lang == 'ar')
          ? TextDirection.rtl
          : TextDirection.ltr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

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
        textDirection: _textDirection,
        child: child ?? const SizedBox.shrink(),
      ),

      // ===============================
      // Entry Page
      // ===============================
      home: const IntroPage(),
    );
  }
}
