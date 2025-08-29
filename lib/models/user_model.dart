import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserType {
  parent,
  supervisor,
  admin,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        id: map['id']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        userType: _parseUserType(map['userType']?.toString()),
        createdAt: _parseTimestamp(map['createdAt']),
        updatedAt: _parseTimestamp(map['updatedAt']),
        isActive: map['isActive'] == true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحويل بيانات المستخدم: $e');
      debugPrint('📄 البيانات المستلمة: $map');
      rethrow;
    }
  }

  // Helper method to safely parse Timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Helper method to parse UserType from string
  static UserType _parseUserType(String? userTypeString) {
    switch (userTypeString) {
      case 'parent':
        return UserType.parent;
      case 'supervisor':
        return UserType.supervisor;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.parent;
    }
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, phone: $phone, userType: $userType, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
