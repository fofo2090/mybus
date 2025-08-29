import 'dart:convert';

/// أولوية الإشعار للمشرف
enum SupervisorNotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// نموذج إشعار المشرف
class SupervisorNotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final SupervisorNotificationPriority priority;
  final String? studentId;
  final String? busId;
  final String? routeId;

  const SupervisorNotificationModel({
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
    this.routeId,
  });

  /// إنشاء نسخة معدلة
  SupervisorNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    SupervisorNotificationPriority? priority,
    String? studentId,
    String? busId,
    String? routeId,
  }) {
    return SupervisorNotificationModel(
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
      routeId: routeId ?? this.routeId,
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
      'routeId': routeId,
    };
  }

  /// إنشاء من Map
  factory SupervisorNotificationModel.fromMap(Map<String, dynamic> map) {
    return SupervisorNotificationModel(
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
      routeId: map['routeId'],
    );
  }

  /// تحليل الأولوية من النص
  static SupervisorNotificationPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return SupervisorNotificationPriority.low;
      case 'high':
        return SupervisorNotificationPriority.high;
      case 'urgent':
        return SupervisorNotificationPriority.urgent;
      default:
        return SupervisorNotificationPriority.normal;
    }
  }

  /// تحويل إلى JSON
  String toJson() => json.encode(toMap());

  /// إنشاء من JSON
  factory SupervisorNotificationModel.fromJson(String source) =>
      SupervisorNotificationModel.fromMap(json.decode(source));

  /// الحصول على لون الأولوية
  String get priorityColor {
    switch (priority) {
      case SupervisorNotificationPriority.low:
        return '#4CAF50'; // أخضر
      case SupervisorNotificationPriority.normal:
        return '#FF9800'; // برتقالي (لون المشرف)
      case SupervisorNotificationPriority.high:
        return '#F44336'; // أحمر
      case SupervisorNotificationPriority.urgent:
        return '#9C27B0'; // بنفسجي
    }
  }

  /// الحصول على نص الأولوية
  String get priorityText {
    switch (priority) {
      case SupervisorNotificationPriority.low:
        return 'منخفضة';
      case SupervisorNotificationPriority.normal:
        return 'عادية';
      case SupervisorNotificationPriority.high:
        return 'عالية';
      case SupervisorNotificationPriority.urgent:
        return 'عاجلة';
    }
  }

  /// الحصول على أيقونة النوع
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'student_attendance':
        return '✅';
      case 'student_absence':
        return '❌';
      case 'student_behavior':
        return '⭐';
      case 'student_incident':
        return '⚠️';
      case 'route_start':
        return '🚀';
      case 'route_complete':
        return '🏁';
      case 'route_delay':
        return '⏰';
      case 'bus_maintenance':
        return '🔧';
      case 'bus_breakdown':
        return '🚨';
      case 'emergency':
        return '🆘';
      case 'schedule_change':
        return '📅';
      case 'admin_message':
        return '📢';
      case 'system_update':
        return '🔄';
      default:
        return '📋';
    }
  }

  /// الحصول على وصف النوع
  String get typeDescription {
    switch (type.toLowerCase()) {
      case 'student_attendance':
        return 'حضور الطالب';
      case 'student_absence':
        return 'غياب الطالب';
      case 'student_behavior':
        return 'سلوك الطالب';
      case 'student_incident':
        return 'حادث طالب';
      case 'route_start':
        return 'بداية الرحلة';
      case 'route_complete':
        return 'انتهاء الرحلة';
      case 'route_delay':
        return 'تأخير الرحلة';
      case 'bus_maintenance':
        return 'صيانة الحافلة';
      case 'bus_breakdown':
        return 'عطل الحافلة';
      case 'emergency':
        return 'حالة طوارئ';
      case 'schedule_change':
        return 'تغيير الجدول';
      case 'admin_message':
        return 'رسالة إدارية';
      case 'system_update':
        return 'تحديث النظام';
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

  /// الحصول على اسم الطريق من البيانات
  String? get routeName {
    return data['routeName'] as String?;
  }

  /// الحصول على الموقع من البيانات
  String? get location {
    return data['location'] as String?;
  }

  /// التحقق من وجود إجراء مطلوب
  bool get requiresAction {
    return type.toLowerCase() == 'student_incident' || 
           type.toLowerCase() == 'bus_breakdown' ||
           type.toLowerCase() == 'emergency' ||
           type.toLowerCase() == 'schedule_change';
  }

  /// الحصول على نص الإجراء المطلوب
  String? get actionText {
    switch (type.toLowerCase()) {
      case 'student_incident':
        return 'التعامل مع الحادث';
      case 'bus_breakdown':
        return 'طلب المساعدة';
      case 'emergency':
        return 'إجراء طوارئ';
      case 'schedule_change':
        return 'مراجعة الجدول';
      default:
        return null;
    }
  }

  /// التحقق من كون الإشعار متعلق بطالب محدد
  bool get isStudentRelated {
    return studentId != null || studentName != null ||
           type.toLowerCase().contains('student');
  }

  /// التحقق من كون الإشعار متعلق بحافلة محددة
  bool get isBusRelated {
    return busId != null || busNumber != null ||
           type.toLowerCase().contains('bus');
  }

  /// التحقق من كون الإشعار متعلق بطريق محدد
  bool get isRouteRelated {
    return routeId != null || routeName != null ||
           type.toLowerCase().contains('route');
  }

  /// الحصول على الوقت المتوقع من البيانات
  String? get expectedTime {
    return data['expectedTime'] as String?;
  }

  /// الحصول على سبب التأخير من البيانات
  String? get delayReason {
    return data['delayReason'] as String?;
  }

  /// التحقق من كون الإشعار يتطلب تأكيد
  bool get requiresConfirmation {
    return type.toLowerCase() == 'route_start' ||
           type.toLowerCase() == 'route_complete' ||
           type.toLowerCase() == 'student_attendance';
  }

  @override
  String toString() {
    return 'SupervisorNotificationModel(id: $id, title: $title, type: $type, priority: $priority, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupervisorNotificationModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
