class NotificationModel {
  final String id;
  final String recipient;
  final String? sender;
  final String type;
  final String title;
  final String message;
  final String? relatedRecipe;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipient,
    this.sender,
    required this.type,
    required this.title,
    required this.message,
    this.relatedRecipe,
    this.data,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      recipient: json['recipient'] is String ? json['recipient'] : (json['recipient']?['_id'] ?? ''),
      sender: json['sender'] is String ? json['sender'] : (json['sender']?['_id']),
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedRecipe: json['relatedRecipe'] is String ? json['relatedRecipe'] : (json['relatedRecipe']?['_id']),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipient,
      'sender': sender,
      'type': type,
      'title': title,
      'message': message,
      'relatedRecipe': relatedRecipe,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipient,
    String? sender,
    String? type,
    String? title,
    String? message,
    String? relatedRecipe,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedRecipe: relatedRecipe ?? this.relatedRecipe,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
