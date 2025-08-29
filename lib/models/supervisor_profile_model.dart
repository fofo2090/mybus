import 'package:cloud_firestore/cloud_firestore.dart';

class SupervisorProfileModel {
  final String id;
  final String fullName;
  final String address;
  final String phone;
  final String nationalId;
  final String qualification;
  final String busAssignment;
  final String email;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  SupervisorProfileModel({
    required this.id,
    required this.fullName,
    required this.address,
    required this.phone,
    required this.nationalId,
    required this.qualification,
    required this.busAssignment,
    required this.email,
    required this.isProfileComplete,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Convert SupervisorProfileModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'address': address,
      'phone': phone,
      'nationalId': nationalId,
      'qualification': qualification,
      'busAssignment': busAssignment,
      'email': email,
      'isProfileComplete': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create SupervisorProfileModel from Firestore document
  factory SupervisorProfileModel.fromMap(Map<String, dynamic> map) {
    return SupervisorProfileModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      nationalId: map['nationalId'] ?? '',
      qualification: map['qualification'] ?? '',
      busAssignment: map['busAssignment'] ?? '',
      email: map['email'] ?? '',
      isProfileComplete: map['isProfileComplete'] ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  // Helper method to parse Firestore timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  SupervisorProfileModel copyWith({
    String? id,
    String? fullName,
    String? address,
    String? phone,
    String? nationalId,
    String? qualification,
    String? busAssignment,
    String? email,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return SupervisorProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      qualification: qualification ?? this.qualification,
      busAssignment: busAssignment ?? this.busAssignment,
      email: email ?? this.email,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasRequiredData {
    return fullName.isNotEmpty &&
           address.isNotEmpty &&
           phone.isNotEmpty &&
           nationalId.isNotEmpty &&
           qualification.isNotEmpty;
  }

  String get displayName {
    return fullName.isNotEmpty ? fullName : email;
  }

  String get initials {
    if (fullName.isEmpty) return 'م';
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}';
    }
    return fullName[0];
  }

  String get busAssignmentDisplay {
    return busAssignment.isNotEmpty ? busAssignment : 'لم يتم التعيين بعد';
  }

  String get qualificationDisplay {
    return qualification.isNotEmpty ? qualification : 'غير محدد';
  }

  @override
  String toString() {
    return 'SupervisorProfileModel(id: $id, fullName: $fullName, phone: $phone, busAssignment: $busAssignment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupervisorProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Qualifications enum for dropdown
class SupervisorQualifications {
  static const List<String> qualifications = [
    'دبلوم',
    'بكالوريوس',
    'ماجستير',
    'دكتوراه',
    'ثانوية عامة',
    'دبلوم فني',
    'معهد متوسط',
    'أخرى',
  ];
}
