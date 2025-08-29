import 'dart:convert';

/// أولوية الإشعار
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// نموذج إشعار الأدمن
class AdminNotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final NotificationPriority priority;

  const AdminNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    required this.isRead,
    required this.type,
    required this.priority,
  });

  /// إنشاء نسخة معدلة
  AdminNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    NotificationPriority? priority,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      priority: priority ?? this.priority,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'priority': priority.toString().split('.').last,
    };
  }

  /// إنشاء من Map
  factory AdminNotificationModel.fromMap(Map<String, dynamic> map) {
    return AdminNotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'general',
      priority: _parsePriority(map['priority']),
    );
  }

  /// تحليل الأولوية من النص
  static NotificationPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  /// تحويل إلى JSON
  String toJson() => json.encode(toMap());

  /// إنشاء من JSON
  factory AdminNotificationModel.fromJson(String source) =>
      AdminNotificationModel.fromMap(json.decode(source));

  /// الحصول على لون الأولوية
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return '#4CAF50'; // أخضر
      case NotificationPriority.normal:
        return '#2196F3'; // أزرق
      case NotificationPriority.high:
        return '#FF9800'; // برتقالي
      case NotificationPriority.urgent:
        return '#F44336'; // أحمر
    }
  }

  /// الحصول على نص الأولوية
  String get priorityText {
    switch (priority) {
      case NotificationPriority.low:
        return 'منخفضة';
      case NotificationPriority.normal:
        return 'عادية';
      case NotificationPriority.high:
        return 'عالية';
      case NotificationPriority.urgent:
        return 'عاجلة';
    }
  }

  /// الحصول على أيقونة النوع
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'student':
        return '👨‍🎓';
      case 'bus':
        return '🚌';
      case 'complaint':
        return '📝';
      case 'emergency':
        return '🚨';
      case 'system':
        return '⚙️';
      case 'backup':
        return '💾';
      default:
        return '📢';
    }
  }

  /// الحصول على وصف النوع
  String get typeDescription {
    switch (type.toLowerCase()) {
      case 'student':
        return 'إشعار طالب';
      case 'bus':
        return 'إشعار حافلة';
      case 'complaint':
        return 'شكوى جديدة';
      case 'emergency':
        return 'حالة طوارئ';
      case 'system':
        return 'إشعار نظام';
      case 'backup':
        return 'نسخ احتياطي';
      default:
        return 'إشعار عام';
    }
  }

  /// تنسيق الوقت
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// التحقق من كون الإشعار جديد (أقل من 5 دقائق)
  bool get isNew {
    final difference = DateTime.now().difference(timestamp);
    return difference.inMinutes < 5;
  }

  @override
  String toString() {
    return 'AdminNotificationModel(id: $id, title: $title, type: $type, priority: $priority, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminNotificationModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
