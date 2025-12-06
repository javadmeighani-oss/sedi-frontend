import 'package:flutter/material.dart';
import 'features/chat/presentation/pages/chat_page.dart';

class SediApp extends StatelessWidget {
  const SediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sedi Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7CB342), // سبز پسته‌ای
        ),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}
