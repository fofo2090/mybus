import 'package:cloud_firestore/cloud_firestore.dart';

enum AbsenceType {
  sick,           // مرض
  family,         // ظروف عائلية
  travel,         // سفر
  emergency,      // طوارئ
  other,          // أخرى
}

enum AbsenceStatus {
  pending,        // معلق
  approved,       // مقبول
  rejected,       // مرفوض
}

enum AbsenceSource {
  parent,         // من ولي الأمر
  supervisor,     // من المشرف
  admin,          // من الإدارة
  system,         // من النظام (تلقائي)
}

class AbsenceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String parentId;
  final String? supervisorId;
  final String? adminId;
  final AbsenceType type;
  final AbsenceStatus status;
  final AbsenceSource source;
  final DateTime date;
  final DateTime? endDate; // للغياب لعدة أيام
  final String reason;
  final String? notes;
  final String? attachmentUrl; // رابط المستند المرفق
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  AbsenceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.parentId,
    this.supervisorId,
    this.adminId,
    required this.type,
    required this.status,
    required this.source,
    required this.date,
    this.endDate,
    required this.reason,
    this.notes,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'parentId': parentId,
      'supervisorId': supervisorId,
      'adminId': adminId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'source': source.toString().split('.').last,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'reason': reason,
      'notes': notes,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  // Create from Firestore document
  factory AbsenceModel.fromMap(Map<String, dynamic> map) {
    return AbsenceModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      parentId: map['parentId'] ?? '',
      supervisorId: map['supervisorId'],
      adminId: map['adminId'],
      type: _parseAbsenceType(map['type']),
      status: _parseAbsenceStatus(map['status']),
      source: _parseAbsenceSource(map['source']),
      date: _parseTimestamp(map['date']),
      endDate: map['endDate'] != null ? _parseTimestamp(map['endDate']) : null,
      reason: map['reason'] ?? '',
      notes: map['notes'],
      attachmentUrl: map['attachmentUrl'],
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null ? _parseTimestamp(map['approvedAt']) : null,
      rejectionReason: map['rejectionReason'],
    );
  }

  // Helper methods for parsing
  static AbsenceType _parseAbsenceType(String? type) {
    switch (type) {
      case 'sick':
        return AbsenceType.sick;
      case 'family':
        return AbsenceType.family;
      case 'travel':
        return AbsenceType.travel;
      case 'emergency':
        return AbsenceType.emergency;
      case 'other':
        return AbsenceType.other;
      default:
        return AbsenceType.other;
    }
  }

  static AbsenceStatus _parseAbsenceStatus(String? status) {
    switch (status) {
      case 'pending':
        return AbsenceStatus.pending;
      case 'approved':
        return AbsenceStatus.approved;
      case 'rejected':
        return AbsenceStatus.rejected;
      default:
        return AbsenceStatus.pending;
    }
  }

  static AbsenceSource _parseAbsenceSource(String? source) {
    switch (source) {
      case 'parent':
        return AbsenceSource.parent;
      case 'supervisor':
        return AbsenceSource.supervisor;
      case 'admin':
        return AbsenceSource.admin;
      case 'system':
        return AbsenceSource.system;
      default:
        return AbsenceSource.parent;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }

  // Helper getters for display
  String get typeDisplayText {
    switch (type) {
      case AbsenceType.sick:
        return 'مرض';
      case AbsenceType.family:
        return 'ظروف عائلية';
      case AbsenceType.travel:
        return 'سفر';
      case AbsenceType.emergency:
        return 'طوارئ';
      case AbsenceType.other:
        return 'أخرى';
    }
  }

  String get statusDisplayText {
    switch (status) {
      case AbsenceStatus.pending:
        return 'معلق';
      case AbsenceStatus.approved:
        return 'مقبول';
      case AbsenceStatus.rejected:
        return 'مرفوض';
    }
  }

  String get sourceDisplayText {
    switch (source) {
      case AbsenceSource.parent:
        return 'ولي الأمر';
      case AbsenceSource.supervisor:
        return 'المشرف';
      case AbsenceSource.admin:
        return 'الإدارة';
      case AbsenceSource.system:
        return 'النظام';
    }
  }

  // Check if absence is for multiple days
  bool get isMultipleDays => endDate != null && endDate!.isAfter(date);

  // Get duration in days
  int get durationInDays {
    if (endDate == null) return 1;
    return endDate!.difference(date).inDays + 1;
  }

  // Check if absence is current/active
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final absenceDate = DateTime(date.year, date.month, date.day);
    
    if (endDate == null) {
      return absenceDate.isAtSameMomentAs(today);
    } else {
      final endAbsenceDate = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return today.isAfter(absenceDate.subtract(const Duration(days: 1))) && 
             today.isBefore(endAbsenceDate.add(const Duration(days: 1)));
    }
  }

  // Copy with method for updates
  AbsenceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? parentId,
    String? supervisorId,
    String? adminId,
    AbsenceType? type,
    AbsenceStatus? status,
    AbsenceSource? source,
    DateTime? date,
    DateTime? endDate,
    String? reason,
    String? notes,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return AbsenceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      parentId: parentId ?? this.parentId,
      supervisorId: supervisorId ?? this.supervisorId,
      adminId: adminId ?? this.adminId,
      type: type ?? this.type,
      status: status ?? this.status,
      source: source ?? this.source,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
