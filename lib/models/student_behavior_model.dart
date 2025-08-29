import 'package:cloud_firestore/cloud_firestore.dart';

enum BehaviorRating {
  excellent,  // ممتاز (5)
  veryGood,   // جيد جداً (4)
  good,       // جيد (3)
  fair,       // مقبول (2)
  poor,       // ضعيف (1)
}

enum BehaviorCategory {
  discipline,     // الانضباط
  respect,        // الاحترام
  cooperation,    // التعاون
  cleanliness,    // النظافة
  safety,         // السلامة
  communication,  // التواصل
}

class StudentBehaviorEvaluation {
  final String id;
  final String studentId;
  final String studentName;
  final String supervisorId;
  final String supervisorName;
  final String busId;
  final String busRoute;
  final int month;
  final int year;
  final Map<BehaviorCategory, BehaviorRating> ratings;
  final String generalNotes;
  final List<String> positivePoints;
  final List<String> improvementAreas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSubmitted;

  StudentBehaviorEvaluation({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.supervisorId,
    required this.supervisorName,
    required this.busId,
    required this.busRoute,
    required this.month,
    required this.year,
    required this.ratings,
    this.generalNotes = '',
    this.positivePoints = const [],
    this.improvementAreas = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSubmitted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'busId': busId,
      'busRoute': busRoute,
      'month': month,
      'year': year,
      'ratings': ratings.map((key, value) => MapEntry(
        key.toString().split('.').last,
        value.toString().split('.').last,
      )),
      'generalNotes': generalNotes,
      'positivePoints': positivePoints,
      'improvementAreas': improvementAreas,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isSubmitted': isSubmitted,
    };
  }

  factory StudentBehaviorEvaluation.fromMap(Map<String, dynamic> map) {
    final ratingsMap = <BehaviorCategory, BehaviorRating>{};
    final ratingsData = map['ratings'] as Map<String, dynamic>? ?? {};
    
    for (final entry in ratingsData.entries) {
      final category = _parseBehaviorCategory(entry.key);
      final rating = _parseBehaviorRating(entry.value);
      if (category != null && rating != null) {
        ratingsMap[category] = rating;
      }
    }

    return StudentBehaviorEvaluation(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      busId: map['busId'] ?? '',
      busRoute: map['busRoute'] ?? '',
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      ratings: ratingsMap,
      generalNotes: map['generalNotes'] ?? '',
      positivePoints: List<String>.from(map['positivePoints'] ?? []),
      improvementAreas: List<String>.from(map['improvementAreas'] ?? []),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      isSubmitted: map['isSubmitted'] ?? false,
    );
  }

  static BehaviorCategory? _parseBehaviorCategory(String? category) {
    switch (category) {
      case 'discipline': return BehaviorCategory.discipline;
      case 'respect': return BehaviorCategory.respect;
      case 'cooperation': return BehaviorCategory.cooperation;
      case 'cleanliness': return BehaviorCategory.cleanliness;
      case 'safety': return BehaviorCategory.safety;
      case 'communication': return BehaviorCategory.communication;
      default: return null;
    }
  }

  static BehaviorRating? _parseBehaviorRating(String? rating) {
    switch (rating) {
      case 'excellent': return BehaviorRating.excellent;
      case 'veryGood': return BehaviorRating.veryGood;
      case 'good': return BehaviorRating.good;
      case 'fair': return BehaviorRating.fair;
      case 'poor': return BehaviorRating.poor;
      default: return null;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  StudentBehaviorEvaluation copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? supervisorId,
    String? supervisorName,
    String? busId,
    String? busRoute,
    int? month,
    int? year,
    Map<BehaviorCategory, BehaviorRating>? ratings,
    String? generalNotes,
    List<String>? positivePoints,
    List<String>? improvementAreas,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSubmitted,
  }) {
    return StudentBehaviorEvaluation(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
      busId: busId ?? this.busId,
      busRoute: busRoute ?? this.busRoute,
      month: month ?? this.month,
      year: year ?? this.year,
      ratings: ratings ?? this.ratings,
      generalNotes: generalNotes ?? this.generalNotes,
      positivePoints: positivePoints ?? this.positivePoints,
      improvementAreas: improvementAreas ?? this.improvementAreas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  // Helper methods
  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.values.map((rating) => _getRatingValue(rating)).reduce((a, b) => a + b);
    return total / ratings.length;
  }

  String get averageRatingText {
    final avg = averageRating;
    if (avg >= 4.5) return 'ممتاز';
    if (avg >= 3.5) return 'جيد جداً';
    if (avg >= 2.5) return 'جيد';
    if (avg >= 1.5) return 'مقبول';
    return 'يحتاج تحسين';
  }

  String get monthYearText {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[month]} $year';
  }

  static int _getRatingValue(BehaviorRating rating) {
    switch (rating) {
      case BehaviorRating.excellent: return 5;
      case BehaviorRating.veryGood: return 4;
      case BehaviorRating.good: return 3;
      case BehaviorRating.fair: return 2;
      case BehaviorRating.poor: return 1;
    }
  }

  static String getBehaviorCategoryName(BehaviorCategory category) {
    switch (category) {
      case BehaviorCategory.discipline: return 'الانضباط';
      case BehaviorCategory.respect: return 'الاحترام';
      case BehaviorCategory.cooperation: return 'التعاون';
      case BehaviorCategory.cleanliness: return 'النظافة';
      case BehaviorCategory.safety: return 'السلامة';
      case BehaviorCategory.communication: return 'التواصل';
    }
  }

  static String getBehaviorRatingName(BehaviorRating rating) {
    switch (rating) {
      case BehaviorRating.excellent: return 'ممتاز';
      case BehaviorRating.veryGood: return 'جيد جداً';
      case BehaviorRating.good: return 'جيد';
      case BehaviorRating.fair: return 'مقبول';
      case BehaviorRating.poor: return 'ضعيف';
    }
  }

  static List<BehaviorCategory> getAllCategories() {
    return [
      BehaviorCategory.discipline,
      BehaviorCategory.respect,
      BehaviorCategory.cooperation,
      BehaviorCategory.cleanliness,
      BehaviorCategory.safety,
      BehaviorCategory.communication,
    ];
  }

  static List<BehaviorRating> getAllRatings() {
    return [
      BehaviorRating.excellent,
      BehaviorRating.veryGood,
      BehaviorRating.good,
      BehaviorRating.fair,
      BehaviorRating.poor,
    ];
  }
}
