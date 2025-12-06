import 'package:flutter/material.dart';
import '../chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// تاریخچه پیام‌ها
  List<String> chatHistory = [];

  /// آخرین پیام صدی
  String lastReply = "سلام، من صدی هستم 😊\nچطور می‌تونم کمکت کنم؟";
  bool isThinking = false;

  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // انیمیشن حلقه دور لوگو
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    /// ذخیره پیام کاربر در تاریخچه
    setState(() {
      chatHistory.add("USER: $userMessage");
      isThinking = true;
      lastReply = "در حال فکر کردن… ⏳";
    });

    final response = await _chatService.sendMessage(userMessage);

    setState(() {
      isThinking = false;
      lastReply = response;

      /// ذخیره پیام صدی در تاریخچه
      chatHistory.add("SEDI: $response");
    });

    /// اسکرول خودکار به پایین
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔵 لوگو + انیمیشن
            ScaleTransition(
              scale: _pulseAnim,
              child: Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF9BCF9B),
                      width: 8,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/images/sedi_logo.png",
                      width: 85,
                      height: 85,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// 🔵 آخرین پیام صدی (همیشه پایین)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  lastReply,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔵 اسکرول‌بار + تاریخچه
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 12,
                radius: const Radius.circular(12),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: chatHistory.length,
                  itemBuilder: (context, index) {
                    final msg = chatHistory[index];

                    /// پیام‌های USER نمایش داده نمی‌شود
                    if (msg.startsWith("USER:")) {
                      return const SizedBox(height: 0);
                    }

                    /// نمایش پیام‌های قدیمی صدی
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Text(
                        msg.replaceFirst("SEDI: ", ""),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// 🔵 چت‌باکس
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "پیامت را بنویس…",
                          hintStyle: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Color(0xFF9BCF9B)),
                    iconSize: 30,
                    onPressed: () {},
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF9BCF9B),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
