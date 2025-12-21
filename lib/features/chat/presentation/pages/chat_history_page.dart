import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ------------------------------------------------------------
/// ChatHistoryPage
///
/// RESPONSIBILITY:
/// - Display previous chat sessions (UI only)
/// - No dependency on chat state or message models
/// - Fully aligned with Sedi AppTheme
/// ------------------------------------------------------------
class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = _mockHistory();

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryBlack,
        title: const Text(
          'Chat History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: history.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppTheme.metalGrey.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          final day = history[index];
          return _HistoryDayTile(
            day: day,
            onTap: () {
              // Later: load selected chat session
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
/// MOCK DATA (Temporary)
/// ------------------------------------------------------------
List<_HistoryDay> _mockHistory() {
  return [
    _HistoryDay(
      title: 'Today',
      lastMessage: 'Sedi is here to help you…',
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
/// - Visual representation of one chat session
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Date / Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              Icons.chevron_right,
              color: AppTheme.metalGrey,
            ),
          ],
        ),
      ),
    );
  }
}
