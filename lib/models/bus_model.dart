import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BusModel {
  final String id;
  final String plateNumber;
  final String description;
  final String driverName;
  final String driverPhone;
  final String driverNationalId; // Driver's national ID
  final bool hasAirConditioning;
  final int capacity;
  final String route;
  final String? imageUrl; // URL of bus image
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusModel({
    required this.id,
    required this.plateNumber,
    required this.description,
    required this.driverName,
    required this.driverPhone,
    this.driverNationalId = '', // Default empty national ID
    this.hasAirConditioning = false,
    this.capacity = 30,
    required this.route,
    this.imageUrl, // Optional bus image
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert BusModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'description': description,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverNationalId': driverNationalId,
      'hasAirConditioning': hasAirConditioning,
      'capacity': capacity,
      'route': route,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create BusModel from Firestore document
  factory BusModel.fromMap(Map<String, dynamic> map) {
    try {
      return BusModel(
        id: map['id'] ?? '',
        plateNumber: map['plateNumber'] ?? '',
        description: map['description'] ?? '',
        driverName: map['driverName'] ?? '',
        driverPhone: map['driverPhone'] ?? '',
        driverNationalId: map['driverNationalId'] ?? '',
        hasAirConditioning: map['hasAirConditioning'] ?? false,
        capacity: map['capacity'] ?? 30,
        route: map['route'] ?? '',
        imageUrl: map['imageUrl'],
        isActive: map['isActive'] ?? true,
        createdAt: _parseTimestamp(map['createdAt']),
        updatedAt: _parseTimestamp(map['updatedAt']),
      );
    } catch (e) {
      debugPrint('❌ Error creating BusModel from map: $e');
      debugPrint('📝 Map data: $map');
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

  // Create a copy of BusModel with updated fields
  BusModel copyWith({
    String? id,
    String? plateNumber,
    String? description,
    String? driverName,
    String? driverPhone,
    String? driverNationalId,
    bool? hasAirConditioning,
    int? capacity,
    String? route,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      description: description ?? this.description,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverNationalId: driverNationalId ?? this.driverNationalId,
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      capacity: capacity ?? this.capacity,
      route: route ?? this.route,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get air conditioning status in Arabic
  String get airConditioningStatus {
    return hasAirConditioning ? 'مكيفة' : 'غير مكيفة';
  }

  // Get formatted capacity
  String get formattedCapacity {
    return '$capacity راكب';
  }

  @override
  String toString() {
    return 'BusModel(id: $id, plateNumber: $plateNumber, driverName: $driverName, route: $route)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
