import '../dto/notifications/notification_item_dto.dart';

class NotificationItem {
  final int id;
  final String channel;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? priority;
  final String? status;
  final String? dedupeKey;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.priority,
    this.status,
    this.dedupeKey,
    this.metadata,
  });

  factory NotificationItem.fromDto(NotificationItemDto dto) {
    return NotificationItem(
      id: dto.id,
      channel: dto.channel,
      title: dto.title,
      body: dto.body,
      createdAt: dto.createdAt,
      isRead: dto.isRead,
      priority: dto.priority,
      status: dto.status,
      dedupeKey: dto.dedupeKey,
      metadata: dto.metadata,
    );
  }

  NotificationItem copyWith({
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      channel: channel,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      priority: priority,
      status: status,
      dedupeKey: dedupeKey,
      metadata: metadata,
    );
  }
}
