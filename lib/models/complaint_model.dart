import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintType {
  busService,      // خدمة الباص
  driverBehavior,  // سلوك السائق
  safety,          // السلامة
  timing,          // التوقيت
  communication,   // التواصل
  other,           // أخرى
}

enum ComplaintStatus {
  pending,    // في انتظار المراجعة
  inProgress, // قيد المعالجة
  resolved,   // تم الحل
  closed,     // مغلقة
}

enum ComplaintPriority {
  low,    // منخفضة
  medium, // متوسطة
  high,   // عالية
  urgent, // عاجلة
}

class ComplaintModel {
  final String id;
  final String parentId;
  final String parentName;
  final String parentPhone;
  final String? studentId;
  final String? studentName;
  final String title;
  final String description;
  final ComplaintType type;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final List<String> attachments; // URLs للمرفقات
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo; // معرف الموظف المكلف
  final String? adminResponse; // رد الإدارة
  final DateTime? responseDate; // تاريخ الرد
  final bool isActive;

  const ComplaintModel({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.parentPhone,
    this.studentId,
    this.studentName,
    required this.title,
    required this.description,
    required this.type,
    this.status = ComplaintStatus.pending,
    this.priority = ComplaintPriority.medium,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.adminResponse,
    this.responseDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedTo': assignedTo,
      'adminResponse': adminResponse,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'isActive': isActive,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id'] ?? '',
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      studentId: map['studentId'],
      studentName: map['studentName'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _parseComplaintType(map['type']),
      status: _parseComplaintStatus(map['status']),
      priority: _parseComplaintPriority(map['priority']),
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      assignedTo: map['assignedTo'],
      adminResponse: map['adminResponse'],
      responseDate: map['responseDate'] != null ? _parseTimestamp(map['responseDate']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  static ComplaintType _parseComplaintType(String? type) {
    switch (type) {
      case 'busService':
        return ComplaintType.busService;
      case 'driverBehavior':
        return ComplaintType.driverBehavior;
      case 'safety':
        return ComplaintType.safety;
      case 'timing':
        return ComplaintType.timing;
      case 'communication':
        return ComplaintType.communication;
      case 'other':
        return ComplaintType.other;
      default:
        return ComplaintType.other;
    }
  }

  static ComplaintStatus _parseComplaintStatus(String? status) {
    switch (status) {
      case 'pending':
        return ComplaintStatus.pending;
      case 'inProgress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'closed':
        return ComplaintStatus.closed;
      default:
        return ComplaintStatus.pending;
    }
  }

  static ComplaintPriority _parseComplaintPriority(String? priority) {
    switch (priority) {
      case 'low':
        return ComplaintPriority.low;
      case 'medium':
        return ComplaintPriority.medium;
      case 'high':
        return ComplaintPriority.high;
      case 'urgent':
        return ComplaintPriority.urgent;
      default:
        return ComplaintPriority.medium;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  ComplaintModel copyWith({
    String? id,
    String? parentId,
    String? parentName,
    String? parentPhone,
    String? studentId,
    String? studentName,
    String? title,
    String? description,
    ComplaintType? type,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    String? adminResponse,
    DateTime? responseDate,
    bool? isActive,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      adminResponse: adminResponse ?? this.adminResponse,
      responseDate: responseDate ?? this.responseDate,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods for UI
  String get typeDisplayName {
    switch (type) {
      case ComplaintType.busService:
        return 'خدمة الباص';
      case ComplaintType.driverBehavior:
        return 'سلوك السائق';
      case ComplaintType.safety:
        return 'السلامة';
      case ComplaintType.timing:
        return 'التوقيت';
      case ComplaintType.communication:
        return 'التواصل';
      case ComplaintType.other:
        return 'أخرى';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ComplaintStatus.pending:
        return 'في انتظار المراجعة';
      case ComplaintStatus.inProgress:
        return 'قيد المعالجة';
      case ComplaintStatus.resolved:
        return 'تم الحل';
      case ComplaintStatus.closed:
        return 'مغلقة';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case ComplaintPriority.low:
        return 'منخفضة';
      case ComplaintPriority.medium:
        return 'متوسطة';
      case ComplaintPriority.high:
        return 'عالية';
      case ComplaintPriority.urgent:
        return 'عاجلة';
    }
  }

  @override
  String toString() {
    return 'ComplaintModel(id: $id, title: $title, type: $type, status: $status, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplaintModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
