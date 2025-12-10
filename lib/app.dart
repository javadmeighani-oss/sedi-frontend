import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/presentation/pages/chat_page.dart';

class SediApp extends StatelessWidget {
  const SediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sedi - Intelligent Health Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ChatPage(),
    );
  }
}
