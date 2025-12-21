import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// ChatHistoryPage
///
/// RESPONSIBILITY:
/// - Display previous days chat history (UI only)
/// - No dependency on chat state or message models
/// - Safe for CI/CD build (GitHub Actions)
///
/// This page is PRESENTATION ONLY.
/// ------------------------------------------------------------
class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = _mockHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: history.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final day = history[index];
          return _HistoryDayTile(
            day: day,
            onTap: () {
              // Future: navigate & load that day's conversation
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
/// UI MODEL (PRIVATE)
///
/// Used ONLY for ChatHistoryPage rendering.
/// This avoids dependency on real chat entities.
/// ------------------------------------------------------------
class _HistoryDay {
  final String title;
  final String lastMessage;
  final DateTime date;

  _HistoryDay({
    required this.title,
    required this.lastMessage,
    required this.date,
  });
}

/// ------------------------------------------------------------
/// MOCK DATA
///
/// Temporary until chat persistence layer is finalized.
/// ------------------------------------------------------------
List<_HistoryDay> _mockHistory() {
  return [
    _HistoryDay(
      title: 'Today',
      lastMessage: 'Sedi is here to help you...',
      date: DateTime.now(),
    ),
    _HistoryDay(
      title: 'Yesterday',
      lastMessage: 'Remember to drink water 💧',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _HistoryDay(
      title: '12 Jan 2025',
      lastMessage: 'Your daily health summary is ready.',
      date: DateTime(2025, 1, 12),
    ),
  ];
}

/// ------------------------------------------------------------
/// HISTORY DAY TILE
///
/// Single responsibility:
/// - Visual representation of one day
/// ------------------------------------------------------------
class _HistoryDayTile extends StatelessWidget {
  final _HistoryDay day;
  final VoidCallback onTap;

  const _HistoryDayTile({
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        day.title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        day.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
