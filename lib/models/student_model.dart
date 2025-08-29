import 'package:cloud_firestore/cloud_firestore.dart';

enum StudentStatus {
  home,
  onBus,
  atSchool,
}

class StudentModel {
  final String id;
  final String name;
  final String parentId;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final String qrCode;
  final String schoolName;
  final String grade;
  final String busRoute;
  final String busId; // ID of the assigned bus
  final String? photoUrl; // URL of student's photo
  final String address; // Student's address
  final String notes; // Additional notes about the student
  final GeoPoint? location; // Student's current location
  final StudentStatus currentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  StudentModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    required this.qrCode,
    required this.schoolName,
    required this.grade,
    required this.busRoute,
    this.busId = '', // Default empty if no bus assigned
    this.photoUrl, // Optional photo URL
    this.address = '', // Default empty address
    this.notes = '', // Default empty notes
    this.location, // Can be null
    this.currentStatus = StudentStatus.home,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Convert StudentModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'qrCode': qrCode,
      'schoolName': schoolName,
      'grade': grade,
      'busRoute': busRoute,
      'busId': busId,
      'photoUrl': photoUrl,
      'address': address,
      'notes': notes,
      'location': location,
      'currentStatus': currentStatus.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create StudentModel from Firestore document
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      parentEmail: map['parentEmail'] ?? '',
      qrCode: map['qrCode'] ?? '',
      schoolName: map['schoolName'] ?? '',
      grade: map['grade'] ?? '',
      busRoute: map['busRoute'] ?? '',
      busId: map['busId'] ?? '',
      photoUrl: map['photoUrl'],
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      location: map['location'] as GeoPoint?,
      currentStatus: _parseStudentStatus(map['currentStatus']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  // Helper method to safely parse Timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now();
  }

  // Helper method to parse StudentStatus from string
  static StudentStatus _parseStudentStatus(String? statusString) {
    switch (statusString) {
      case 'home':
        return StudentStatus.home;
      case 'onBus':
        return StudentStatus.onBus;
      case 'atSchool':
        return StudentStatus.atSchool;
      default:
        return StudentStatus.home;
    }
  }

  // Create a copy of StudentModel with updated fields
  StudentModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? qrCode,
    String? schoolName,
    String? grade,
    String? busRoute,
    String? busId,
    String? photoUrl,
    String? address,
    String? notes,
    GeoPoint? location,
    StudentStatus? currentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      qrCode: qrCode ?? this.qrCode,
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      busRoute: busRoute ?? this.busRoute,
      busId: busId ?? this.busId,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      currentStatus: currentStatus ?? this.currentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get status display text in Arabic
  String get statusDisplayText {
    switch (currentStatus) {
      case StudentStatus.home:
        return 'في المنزل';
      case StudentStatus.onBus:
        return 'في الباص';
      case StudentStatus.atSchool:
        return 'في المدرسة';
    }
  }

  @override
  String toString() {
    return 'StudentModel(id: $id, name: $name, parentName: $parentName, currentStatus: $currentStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
