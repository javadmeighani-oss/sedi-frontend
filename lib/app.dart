import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/intro/presentation/pages/intro_page.dart';

class SediApp extends StatelessWidget {
  const SediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ===============================
      // Theme (Single Source of Truth)
      // ===============================
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.backgroundWhite,
        fontFamily: 'default',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppTheme.iconInactive,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundWhite,
          elevation: 0,
          iconTheme: IconThemeData(
            color: AppTheme.primaryBlack,
          ),
          titleTextStyle: TextStyle(
            color: AppTheme.primaryBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ===============================
      // Entry Page
      // ===============================
      home: const IntroPage(),
    );
  }
}
