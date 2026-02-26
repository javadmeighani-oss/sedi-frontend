class NotificationFeedbackDto {
  final bool liked;
  final String timestamp;

  const NotificationFeedbackDto({
    required this.liked,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'reaction': liked ? 'like' : 'dislike',
      'timestamp': timestamp,
      'feedback': liked ? 'positive' : 'negative',
    };
  }
}
