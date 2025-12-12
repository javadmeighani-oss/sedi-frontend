import 'package:flutter/material.dart';
import '../../state/chat_controller.dart';
import '../../state/chat_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/message_bubble.dart';

class ChatHistoryPage extends StatelessWidget {
  final ChatController chatController;

  const ChatHistoryPage({
    super.key,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    // دسته‌بندی پیام‌ها بر اساس تاریخ
    final groupedMessages = _groupMessagesByDate(chatController.messages);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chat History',
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: groupedMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: AppTheme.metalGray.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chat history yet',
                    style: TextStyle(
                      color: AppTheme.metalGray,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedMessages.length,
              itemBuilder: (context, index) {
                final group = groupedMessages[index];
                return _buildDateGroup(group['label'] as String, group['messages'] as List<ChatMessage>);
              },
            ),
    );
  }

  Widget _buildDateGroup(String label, List<ChatMessage> messages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // برچسب تاریخ
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.pistachioGreen,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // لیست پیام‌های این دسته
        ...messages.map((message) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: MessageBubble(
                message: message.text,
                isSedi: !message.isUser,
              ),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Map<String, dynamic>> _groupMessagesByDate(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);
    final thisYear = DateTime(now.year, 1, 1);

    final Map<String, List<ChatMessage>> grouped = {
      'Today': [],
      'This Week': [],
      'This Month': [],
      'This Year': [],
      'Older': [],
    };

    for (final message in messages) {
      // استفاده از id به عنوان timestamp (milliseconds)
      final timestamp = int.tryParse(message.id) ?? 0;
      final messageDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

      if (messageDay == today) {
        grouped['Today']!.add(message);
      } else if (messageDate.isAfter(thisWeek.subtract(const Duration(days: 1)))) {
        grouped['This Week']!.add(message);
      } else if (messageDate.isAfter(thisMonth.subtract(const Duration(days: 1)))) {
        grouped['This Month']!.add(message);
      } else if (messageDate.isAfter(thisYear.subtract(const Duration(days: 1)))) {
        grouped['This Year']!.add(message);
      } else {
        grouped['Older']!.add(message);
      }
    }

    // تبدیل به لیست و حذف دسته‌های خالی
    final result = <Map<String, dynamic>>[];
    
    if (grouped['Today']!.isNotEmpty) {
      result.add({'label': 'Today', 'messages': grouped['Today']!});
    }
    if (grouped['This Week']!.isNotEmpty) {
      result.add({'label': 'This Week', 'messages': grouped['This Week']!});
    }
    if (grouped['This Month']!.isNotEmpty) {
      result.add({'label': 'This Month', 'messages': grouped['This Month']!});
    }
    if (grouped['This Year']!.isNotEmpty) {
      result.add({'label': 'This Year', 'messages': grouped['This Year']!});
    }
    if (grouped['Older']!.isNotEmpty) {
      // دسته‌بندی سال‌های قدیمی‌تر
      final olderByYear = <int, List<ChatMessage>>{};
      for (final message in grouped['Older']!) {
        final timestamp = int.tryParse(message.id) ?? 0;
        final messageDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final year = messageDate.year;
        olderByYear.putIfAbsent(year, () => []).add(message);
      }
      
      for (final entry in olderByYear.entries.toList()..sort((a, b) => b.key.compareTo(a.key))) {
        result.add({'label': '${entry.key}', 'messages': entry.value});
      }
    }

    return result;
  }
}

