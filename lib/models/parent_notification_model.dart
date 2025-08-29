import 'dart:convert';

/// أولوية الإشعار لولي الأمر
enum ParentNotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// نموذج إشعار ولي الأمر
class ParentNotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final ParentNotificationPriority priority;
  final String? studentId;
  final String? busId;

  const ParentNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    required this.isRead,
    required this.type,
    required this.priority,
    this.studentId,
    this.busId,
  });

  /// إنشاء نسخة معدلة
  ParentNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    ParentNotificationPriority? priority,
    String? studentId,
    String? busId,
  }) {
    return ParentNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      studentId: studentId ?? this.studentId,
      busId: busId ?? this.busId,
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
      'studentId': studentId,
      'busId': busId,
    };
  }

  /// إنشاء من Map
  factory ParentNotificationModel.fromMap(Map<String, dynamic> map) {
    return ParentNotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'general',
      priority: _parsePriority(map['priority']),
      studentId: map['studentId'],
      busId: map['busId'],
    );
  }

  /// تحليل الأولوية من النص
  static ParentNotificationPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return ParentNotificationPriority.low;
      case 'high':
        return ParentNotificationPriority.high;
      case 'urgent':
        return ParentNotificationPriority.urgent;
      default:
        return ParentNotificationPriority.normal;
    }
  }

  /// تحويل إلى JSON
  String toJson() => json.encode(toMap());

  /// إنشاء من JSON
  factory ParentNotificationModel.fromJson(String source) =>
      ParentNotificationModel.fromMap(json.decode(source));

  /// الحصول على لون الأولوية
  String get priorityColor {
    switch (priority) {
      case ParentNotificationPriority.low:
        return '#4CAF50'; // أخضر
      case ParentNotificationPriority.normal:
        return '#2196F3'; // أزرق
      case ParentNotificationPriority.high:
        return '#FF9800'; // برتقالي
      case ParentNotificationPriority.urgent:
        return '#F44336'; // أحمر
    }
  }

  /// الحصول على نص الأولوية
  String get priorityText {
    switch (priority) {
      case ParentNotificationPriority.low:
        return 'منخفضة';
      case ParentNotificationPriority.normal:
        return 'عادية';
      case ParentNotificationPriority.high:
        return 'عالية';
      case ParentNotificationPriority.urgent:
        return 'عاجلة';
    }
  }

  /// الحصول على أيقونة النوع
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'student_pickup':
        return '🚌';
      case 'student_dropoff':
        return '🏠';
      case 'student_absence':
        return '❌';
      case 'student_behavior':
        return '⭐';
      case 'bus_delay':
        return '⏰';
      case 'bus_breakdown':
        return '🔧';
      case 'emergency':
        return '🚨';
      case 'announcement':
        return '📢';
      case 'payment':
        return '💳';
      case 'survey':
        return '📝';
      default:
        return '📱';
    }
  }

  /// الحصول على وصف النوع
  String get typeDescription {
    switch (type.toLowerCase()) {
      case 'student_pickup':
        return 'ركوب الطالب';
      case 'student_dropoff':
        return 'نزول الطالب';
      case 'student_absence':
        return 'غياب الطالب';
      case 'student_behavior':
        return 'سلوك الطالب';
      case 'bus_delay':
        return 'تأخير الحافلة';
      case 'bus_breakdown':
        return 'عطل الحافلة';
      case 'emergency':
        return 'حالة طوارئ';
      case 'announcement':
        return 'إعلان مهم';
      case 'payment':
        return 'دفع الرسوم';
      case 'survey':
        return 'استبيان';
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

  /// الحصول على اسم الطالب من البيانات
  String? get studentName {
    return data['studentName'] as String?;
  }

  /// الحصول على رقم الحافلة من البيانات
  String? get busNumber {
    return data['busNumber'] as String?;
  }

  /// الحصول على الموقع من البيانات
  String? get location {
    return data['location'] as String?;
  }

  /// التحقق من وجود إجراء مطلوب
  bool get requiresAction {
    return type.toLowerCase() == 'survey' || 
           type.toLowerCase() == 'payment' ||
           type.toLowerCase() == 'emergency';
  }

  /// الحصول على نص الإجراء المطلوب
  String? get actionText {
    switch (type.toLowerCase()) {
      case 'survey':
        return 'إجابة الاستبيان';
      case 'payment':
        return 'دفع الرسوم';
      case 'emergency':
        return 'عرض التفاصيل';
      default:
        return null;
    }
  }

  /// التحقق من كون الإشعار متعلق بطالب محدد
  bool get isStudentRelated {
    return studentId != null || studentName != null;
  }

  /// التحقق من كون الإشعار متعلق بحافلة محددة
  bool get isBusRelated {
    return busId != null || busNumber != null;
  }

  @override
  String toString() {
    return 'ParentNotificationModel(id: $id, title: $title, type: $type, priority: $priority, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParentNotificationModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
