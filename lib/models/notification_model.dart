class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String referenceId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isRead,
    required this.type,
    required this.referenceId,
  });

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      description: description,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      referenceId: referenceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'referenceId': referenceId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: _parseDate(map['timestamp']),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'General',
      referenceId: map['referenceId'] ?? '',
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  final seconds = value.seconds;
  if (seconds is int) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
