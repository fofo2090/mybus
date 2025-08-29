import 'package:cloud_firestore/cloud_firestore.dart';

enum EvaluationCategory {
  communication,    // التواصل
  punctuality,     // الالتزام بالمواعيد
  safety,          // السلامة
  professionalism, // المهنية
  studentCare,     // العناية بالطلاب
}

enum EvaluationRating {
  excellent,  // ممتاز (5)
  veryGood,   // جيد جداً (4)
  good,       // جيد (3)
  fair,       // مقبول (2)
  poor,       // ضعيف (1)
}

class SupervisorEvaluationModel {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final String parentId;
  final String parentName;
  final String studentId;
  final String studentName;
  final String busId;
  final Map<EvaluationCategory, EvaluationRating> ratings;
  final String? comments;
  final String? suggestions;
  final DateTime evaluatedAt;
  final int month;
  final int year;

  const SupervisorEvaluationModel({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.parentId,
    required this.parentName,
    required this.studentId,
    required this.studentName,
    required this.busId,
    required this.ratings,
    this.comments,
    this.suggestions,
    required this.evaluatedAt,
    required this.month,
    required this.year,
  });

  factory SupervisorEvaluationModel.fromMap(Map<String, dynamic> map) {
    final ratingsMap = <EvaluationCategory, EvaluationRating>{};
    final ratingsData = map['ratings'] as Map<String, dynamic>? ?? {};
    
    for (final entry in ratingsData.entries) {
      final category = EvaluationCategory.values.firstWhere(
        (c) => c.toString().split('.').last == entry.key,
        orElse: () => EvaluationCategory.communication,
      );
      final rating = EvaluationRating.values.firstWhere(
        (r) => r.toString().split('.').last == entry.value,
        orElse: () => EvaluationRating.good,
      );
      ratingsMap[category] = rating;
    }

    return SupervisorEvaluationModel(
      id: map['id'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      busId: map['busId'] ?? '',
      ratings: ratingsMap,
      comments: map['comments'],
      suggestions: map['suggestions'],
      evaluatedAt: (map['evaluatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() {
    final ratingsMap = <String, String>{};
    for (final entry in ratings.entries) {
      ratingsMap[entry.key.toString().split('.').last] = 
          entry.value.toString().split('.').last;
    }

    return {
      'id': id,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'parentId': parentId,
      'parentName': parentName,
      'studentId': studentId,
      'studentName': studentName,
      'busId': busId,
      'ratings': ratingsMap,
      'comments': comments,
      'suggestions': suggestions,
      'evaluatedAt': Timestamp.fromDate(evaluatedAt),
      'month': month,
      'year': year,
    };
  }

  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.values.map((r) => _getRatingValue(r)).reduce((a, b) => a + b);
    return total / ratings.length;
  }

  int _getRatingValue(EvaluationRating rating) {
    switch (rating) {
      case EvaluationRating.excellent: return 5;
      case EvaluationRating.veryGood: return 4;
      case EvaluationRating.good: return 3;
      case EvaluationRating.fair: return 2;
      case EvaluationRating.poor: return 1;
    }
  }
}

extension EvaluationCategoryExtension on EvaluationCategory {
  String get displayName {
    switch (this) {
      case EvaluationCategory.communication: return 'التواصل';
      case EvaluationCategory.punctuality: return 'الالتزام بالمواعيد';
      case EvaluationCategory.safety: return 'السلامة';
      case EvaluationCategory.professionalism: return 'المهنية';
      case EvaluationCategory.studentCare: return 'العناية بالطلاب';
    }
  }

  String get description {
    switch (this) {
      case EvaluationCategory.communication: return 'التواصل مع أولياء الأمور والطلاب';
      case EvaluationCategory.punctuality: return 'الالتزام بمواعيد الرحلات';
      case EvaluationCategory.safety: return 'الحفاظ على سلامة الطلاب';
      case EvaluationCategory.professionalism: return 'التعامل المهني والأخلاقي';
      case EvaluationCategory.studentCare: return 'الاهتمام برعاية الطلاب';
    }
  }
}

extension EvaluationRatingExtension on EvaluationRating {
  String get displayName {
    switch (this) {
      case EvaluationRating.excellent: return 'ممتاز';
      case EvaluationRating.veryGood: return 'جيد جداً';
      case EvaluationRating.good: return 'جيد';
      case EvaluationRating.fair: return 'مقبول';
      case EvaluationRating.poor: return 'ضعيف';
    }
  }

  int get value {
    switch (this) {
      case EvaluationRating.excellent: return 5;
      case EvaluationRating.veryGood: return 4;
      case EvaluationRating.good: return 3;
      case EvaluationRating.fair: return 2;
      case EvaluationRating.poor: return 1;
    }
  }
}
