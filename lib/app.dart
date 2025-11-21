import 'package:flutter/material.dart';
import 'features/chat/screens/chat_screen.dart';

class SediApp extends StatelessWidget {
  const SediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sedi AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        primaryColor: const Color(0xFF9BCF9B), // سبز پسته‌ای
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
