import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus {
  active,     // نشط
  inactive,   // غير نشط
  emergency,  // طوارئ (تعيين مؤقت)
}

enum TripDirection {
  toSchool,   // ذهاب للمدرسة
  fromSchool, // عودة من المدرسة
  both,       // كلا الاتجاهين
}

class SupervisorAssignmentModel {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final String busId;
  final String busPlateNumber;
  final String busRoute; // خط السير الذي يعمل عليه المشرف
  final TripDirection direction;
  final AssignmentStatus status;
  final DateTime assignedAt;
  final DateTime? unassignedAt;
  final String assignedBy; // Admin ID who made the assignment
  final String assignedByName;
  final String? notes;
  final bool isEmergencyAssignment;
  final String? originalSupervisorId; // For emergency assignments

  const SupervisorAssignmentModel({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.busId,
    required this.busPlateNumber,
    required this.busRoute,
    required this.direction,
    this.status = AssignmentStatus.active,
    required this.assignedAt,
    this.unassignedAt,
    required this.assignedBy,
    required this.assignedByName,
    this.notes,
    this.isEmergencyAssignment = false,
    this.originalSupervisorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'busId': busId,
      'busPlateNumber': busPlateNumber,
      'busRoute': busRoute,
      'direction': direction.toString().split('.').last,
      'status': status.toString().split('.').last,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'unassignedAt': unassignedAt != null ? Timestamp.fromDate(unassignedAt!) : null,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'notes': notes,
      'isEmergencyAssignment': isEmergencyAssignment,
      'originalSupervisorId': originalSupervisorId,
    };
  }

  factory SupervisorAssignmentModel.fromMap(Map<String, dynamic> map) {
    return SupervisorAssignmentModel(
      id: map['id'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      busId: map['busId'] ?? '',
      busPlateNumber: map['busPlateNumber'] ?? '',
      busRoute: map['busRoute'] ?? '',
      direction: _parseTripDirection(map['direction']),
      status: _parseAssignmentStatus(map['status']),
      assignedAt: _parseTimestamp(map['assignedAt']),
      unassignedAt: map['unassignedAt'] != null ? _parseTimestamp(map['unassignedAt']) : null,
      assignedBy: map['assignedBy'] ?? '',
      assignedByName: map['assignedByName'] ?? '',
      notes: map['notes'],
      isEmergencyAssignment: map['isEmergencyAssignment'] ?? false,
      originalSupervisorId: map['originalSupervisorId'],
    );
  }

  static TripDirection _parseTripDirection(String? direction) {
    switch (direction) {
      case 'toSchool': return TripDirection.toSchool;
      case 'fromSchool': return TripDirection.fromSchool;
      case 'both': return TripDirection.both;
      default: return TripDirection.both;
    }
  }

  static AssignmentStatus _parseAssignmentStatus(String? status) {
    switch (status) {
      case 'active': return AssignmentStatus.active;
      case 'inactive': return AssignmentStatus.inactive;
      case 'emergency': return AssignmentStatus.emergency;
      default: return AssignmentStatus.active;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  SupervisorAssignmentModel copyWith({
    String? id,
    String? supervisorId,
    String? supervisorName,
    String? busId,
    String? busPlateNumber,
    String? busRoute,
    TripDirection? direction,
    AssignmentStatus? status,
    DateTime? assignedAt,
    DateTime? unassignedAt,
    String? assignedBy,
    String? assignedByName,
    String? notes,
    bool? isEmergencyAssignment,
    String? originalSupervisorId,
  }) {
    return SupervisorAssignmentModel(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
      busId: busId ?? this.busId,
      busPlateNumber: busPlateNumber ?? this.busPlateNumber,
      busRoute: busRoute ?? this.busRoute,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      unassignedAt: unassignedAt ?? this.unassignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedByName: assignedByName ?? this.assignedByName,
      notes: notes ?? this.notes,
      isEmergencyAssignment: isEmergencyAssignment ?? this.isEmergencyAssignment,
      originalSupervisorId: originalSupervisorId ?? this.originalSupervisorId,
    );
  }

  String get directionDisplayName {
    switch (direction) {
      case TripDirection.toSchool: return 'ذهاب للمدرسة';
      case TripDirection.fromSchool: return 'عودة من المدرسة';
      case TripDirection.both: return 'ذهاب وعودة';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case AssignmentStatus.active: return 'نشط';
      case AssignmentStatus.inactive: return 'غير نشط';
      case AssignmentStatus.emergency: return 'طوارئ';
    }
  }

  bool get isActive => status == AssignmentStatus.active;
  bool get isEmergency => status == AssignmentStatus.emergency || isEmergencyAssignment;

  String get assignmentTypeDisplay {
    if (isEmergencyAssignment) {
      return 'تعيين طوارئ';
    }
    return 'تعيين عادي';
  }

  @override
  String toString() {
    return 'SupervisorAssignmentModel(id: $id, supervisorName: $supervisorName, busPlateNumber: $busPlateNumber, direction: $directionDisplayName, status: $statusDisplayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupervisorAssignmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Helper class for assignment statistics
class AssignmentStatistics {
  final int totalAssignments;
  final int activeAssignments;
  final int emergencyAssignments;
  final int unassignedBuses;
  final Map<String, int> assignmentsByDirection;

  const AssignmentStatistics({
    required this.totalAssignments,
    required this.activeAssignments,
    required this.emergencyAssignments,
    required this.unassignedBuses,
    required this.assignmentsByDirection,
  });

  factory AssignmentStatistics.empty() {
    return const AssignmentStatistics(
      totalAssignments: 0,
      activeAssignments: 0,
      emergencyAssignments: 0,
      unassignedBuses: 0,
      assignmentsByDirection: {},
    );
  }
}
