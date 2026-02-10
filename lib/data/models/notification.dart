/// ============================================
/// Notification - Contract-Compliant Model
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Exact mirror of contract structure
/// - No UI logic
/// - No business logic
/// - Contract Section 1
/// ============================================

/// Notification Type Enum (Contract Section 2 + backend types)
enum NotificationType {
  info,
  alert,
  reminder,
  checkIn,
  achievement,
  // Backend contract (Release B1)
  morningBrief,
  connectionPing,
  healthAlert,
  deviceDisconnected;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
        return NotificationType.info;
      case 'alert':
        return NotificationType.alert;
      case 'reminder':
        return NotificationType.reminder;
      case 'check_in':
        return NotificationType.checkIn;
      case 'achievement':
        return NotificationType.achievement;
      case 'morning_brief':
        return NotificationType.morningBrief;
      case 'connection_ping':
        return NotificationType.connectionPing;
      case 'health_alert':
        return NotificationType.healthAlert;
      case 'device_disconnected':
        return NotificationType.deviceDisconnected;
      default:
        return NotificationType.info;
    }
  }

  String toContractString() {
    switch (this) {
      case NotificationType.info:
        return 'info';
      case NotificationType.alert:
        return 'alert';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.checkIn:
        return 'check_in';
      case NotificationType.achievement:
        return 'achievement';
      case NotificationType.morningBrief:
        return 'morning_brief';
      case NotificationType.connectionPing:
        return 'connection_ping';
      case NotificationType.healthAlert:
        return 'health_alert';
      case NotificationType.deviceDisconnected:
        return 'device_disconnected';
    }
  }
}

/// Priority Level Enum (Contract Section 3)
enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  static NotificationPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
      case 'critical': // Backend uses "critical"
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  String toContractString() {
    switch (this) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }
}

/// Action Type Enum (Contract Section 4)
enum ActionType {
  quickReply,
  navigate,
  dismiss,
  custom;

  static ActionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'quick_reply':
        return ActionType.quickReply;
      case 'navigate':
        return ActionType.navigate;
      case 'dismiss':
        return ActionType.dismiss;
      case 'custom':
        return ActionType.custom;
      default:
        return ActionType.quickReply; // Default fallback
    }
  }

  String toContractString() {
    switch (this) {
      case ActionType.quickReply:
        return 'quick_reply';
      case ActionType.navigate:
        return 'navigate';
      case ActionType.dismiss:
        return 'dismiss';
      case ActionType.custom:
        return 'custom';
    }
  }
}

/// Action Object (Contract Section 4)
class NotificationAction {
  final String id;
  final String label;
  final ActionType type;
  final Map<String, dynamic>? payload;

  NotificationAction({
    required this.id,
    required this.label,
    required this.type,
    this.payload,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] as String,
      label: json['label'] as String,
      type: ActionType.fromString(json['type'] as String),
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.toContractString(),
      if (payload != null) 'payload': payload,
    };
  }
}

/// Metadata Object (Contract Section 6)
class NotificationMetadata {
  final String? language;
  final String? tone;
  final String? context;
  final String? source;

  NotificationMetadata({
    this.language,
    this.tone,
    this.context,
    this.source,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationMetadata();
    return NotificationMetadata(
      language: json['language'] as String?,
      tone: json['tone'] as String?,
      context: json['context'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (language != null) 'language': language,
      if (tone != null) 'tone': tone,
      if (context != null) 'context': context,
      if (source != null) 'source': source,
    };
  }
}

/// Notification Model (Contract Section 1)
class Notification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String? title;
  final String message;
  final List<NotificationAction>? actions;
  final NotificationMetadata? metadata;
  final String createdAt; // ISO 8601 datetime string
  final bool isRead;

  Notification({
    required this.id,
    required this.type,
    required this.priority,
    this.title,
    required this.message,
    this.actions,
    this.metadata,
    required this.createdAt,
    required this.isRead,
  });

  /// Parses from backend API shape: id (int), type, title, body, priority, is_read, created_at.
  /// Also accepts legacy shape: id (string), message, created_at.
  factory Notification.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final idStr = id is int ? id.toString() : (id?.toString() ?? '');
    final typeStr = json['type']?.toString() ?? 'info';
    final priorityStr = json['priority']?.toString() ?? 'normal';
    // Backend uses "body"; legacy uses "message"
    final message = (json['body'] ?? json['message'])?.toString() ?? '';
    final createdAt = json['created_at'];
    final createdAtStr = createdAt is DateTime
        ? createdAt.toIso8601String()
        : (createdAt?.toString() ?? '');
    return Notification(
      id: idStr,
      type: NotificationType.fromString(typeStr),
      priority: NotificationPriority.fromString(priorityStr),
      title: json['title'] as String?,
      message: message,
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((a) => NotificationAction.fromJson(a as Map<String, dynamic>))
              .toList()
          : null,
      metadata: json['metadata'] != null
          ? NotificationMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      createdAt: createdAtStr,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toContractString(),
      'priority': priority.toContractString(),
      if (title != null) 'title': title,
      'message': message,
      if (actions != null) 'actions': actions!.map((a) => a.toJson()).toList(),
      if (metadata != null) 'metadata': metadata!.toJson(),
      'created_at': createdAt,
      'is_read': isRead,
    };
  }
}

