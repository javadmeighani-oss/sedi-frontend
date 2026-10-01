import '../dto/notifications/notification_item_dto.dart';

class NotificationItem {
  final int id;
  final String channel;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? sentAt;
  final bool isRead;
  /// Explicit A4 user response (LIKE/DISLIKE/TALK). READ alone stays false.
  final bool hasUserResponse;
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
    this.hasUserResponse = false,
    this.sentAt,
    this.priority,
    this.status,
    this.dedupeKey,
    this.metadata,
  });

  /// Attention styling: unread OR missing explicit user response.
  bool get needsAttention => !isRead || !hasUserResponse;

  factory NotificationItem.fromDto(NotificationItemDto dto) {
    return NotificationItem(
      id: dto.id,
      channel: dto.channel,
      title: dto.title,
      body: dto.body,
      createdAt: dto.createdAt,
      sentAt: dto.sentAt,
      isRead: dto.isRead,
      hasUserResponse: dto.hasUserResponse,
      priority: dto.priority,
      status: dto.status,
      dedupeKey: dto.dedupeKey,
      metadata: dto.metadata,
    );
  }

  NotificationItem copyWith({
    bool? isRead,
    bool? hasUserResponse,
  }) {
    return NotificationItem(
      id: id,
      channel: channel,
      title: title,
      body: body,
      createdAt: createdAt,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      hasUserResponse: hasUserResponse ?? this.hasUserResponse,
      priority: priority,
      status: status,
      dedupeKey: dedupeKey,
      metadata: metadata,
    );
  }
}
