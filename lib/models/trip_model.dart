import 'package:cloud_firestore/cloud_firestore.dart';

enum TripType {
  toSchool,
  fromSchool,
}

enum TripAction {
  boardBusToSchool,    // ركب الباص إلى المدرسة
  arriveAtSchool,      // وصل إلى المدرسة
  boardBusToHome,      // ركب الباص إلى المنزل
  arriveAtHome,        // وصل إلى المنزل
  // Keep old values for backward compatibility
  boardBus,
  leaveBus,
}

class TripModel {
  final String id;
  final String studentId;
  final String studentName;
  final String supervisorId;
  final String supervisorName;
  final String busRoute;
  final TripType tripType;
  final TripAction action;
  final DateTime timestamp;
  final String? notes;

  TripModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.supervisorId,
    required this.supervisorName,
    required this.busRoute,
    required this.tripType,
    required this.action,
    required this.timestamp,
    this.notes,
  });

  // Convert TripModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'busRoute': busRoute,
      'tripType': tripType.toString().split('.').last,
      'action': _actionToString(action),
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  // Create TripModel from Firestore document
  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      busRoute: map['busRoute'] ?? '',
      tripType: _parseTripType(map['tripType']),
      action: _parseTripAction(map['action']),
      timestamp: _parseTimestamp(map['timestamp']),
      notes: map['notes'],
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

  // Helper method to parse TripType from string
  static TripType _parseTripType(String? tripTypeString) {
    switch (tripTypeString) {
      case 'toSchool':
        return TripType.toSchool;
      case 'fromSchool':
        return TripType.fromSchool;
      default:
        return TripType.toSchool;
    }
  }

  // Helper method to convert TripAction to string
  static String _actionToString(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
        return 'boardBusToSchool';
      case TripAction.arriveAtSchool:
        return 'arriveAtSchool';
      case TripAction.boardBusToHome:
        return 'boardBusToHome';
      case TripAction.arriveAtHome:
        return 'arriveAtHome';
      case TripAction.boardBus:
        return 'boardBus';
      case TripAction.leaveBus:
        return 'leaveBus';
    }
  }

  // Helper method to parse TripAction from string
  static TripAction _parseTripAction(String? actionString) {
    switch (actionString) {
      case 'boardBusToSchool':
        return TripAction.boardBusToSchool;
      case 'arriveAtSchool':
        return TripAction.arriveAtSchool;
      case 'boardBusToHome':
        return TripAction.boardBusToHome;
      case 'arriveAtHome':
        return TripAction.arriveAtHome;
      case 'boardBus':
        return TripAction.boardBus;
      case 'leaveBus':
        return TripAction.leaveBus;
      default:
        return TripAction.boardBus;
    }
  }

  // Get trip type display text in Arabic
  String get tripTypeDisplayText {
    switch (tripType) {
      case TripType.toSchool:
        return 'ذهاب للمدرسة';
      case TripType.fromSchool:
        return 'عودة من المدرسة';
    }
  }

  // Get action display text in Arabic
  String get actionDisplayText {
    switch (action) {
      case TripAction.boardBusToSchool:
        return 'ركب الباص إلى المدرسة';
      case TripAction.arriveAtSchool:
        return 'وصل إلى المدرسة';
      case TripAction.boardBusToHome:
        return 'ركب الباص إلى المنزل';
      case TripAction.arriveAtHome:
        return 'وصل إلى المنزل';
      case TripAction.boardBus:
        return 'ركوب الباص';
      case TripAction.leaveBus:
        return 'نزول من الباص';
    }
  }

  // Get formatted timestamp
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted date
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  String toString() {
    return 'TripModel(id: $id, studentName: $studentName, action: $action, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
