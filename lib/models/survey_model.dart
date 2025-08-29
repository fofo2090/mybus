import 'package:cloud_firestore/cloud_firestore.dart';

enum SurveyType {
  parentFeedback,      // استبيان ولي الأمر
  supervisorMonthly,   // استبيان المشرفة الشهري
  studentBehavior,     // استبيان سلوك الطلاب
  serviceQuality,      // استبيان جودة الخدمة
  supervisorEvaluation, // تقييم المشرفين من أولياء الأمور
}

enum SurveyStatus {
  active,     // نشط
  completed,  // مكتمل
  archived,   // مؤرشف
}

class SurveyModel {
  final String id;
  final String title;
  final String description;
  final SurveyType type;
  final SurveyStatus status;
  final String createdBy; // ID of admin who created it
  final String createdByName;
  final List<SurveyQuestion> questions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool isActive;

  const SurveyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = SurveyStatus.active,
    required this.createdBy,
    required this.createdByName,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
    };
  }

  factory SurveyModel.fromMap(Map<String, dynamic> map) {
    return SurveyModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _parseSurveyType(map['type']),
      status: _parseSurveyStatus(map['status']),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => SurveyQuestion.fromMap(q))
          .toList() ?? [],
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      expiresAt: map['expiresAt'] != null ? _parseTimestamp(map['expiresAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  static SurveyType _parseSurveyType(String? type) {
    switch (type) {
      case 'parentFeedback': return SurveyType.parentFeedback;
      case 'supervisorMonthly': return SurveyType.supervisorMonthly;
      case 'studentBehavior': return SurveyType.studentBehavior;
      case 'serviceQuality': return SurveyType.serviceQuality;
      default: return SurveyType.parentFeedback;
    }
  }

  static SurveyStatus _parseSurveyStatus(String? status) {
    switch (status) {
      case 'active': return SurveyStatus.active;
      case 'completed': return SurveyStatus.completed;
      case 'archived': return SurveyStatus.archived;
      default: return SurveyStatus.active;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  SurveyModel copyWith({
    String? id,
    String? title,
    String? description,
    SurveyType? type,
    SurveyStatus? status,
    String? createdBy,
    String? createdByName,
    List<SurveyQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return SurveyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case SurveyType.parentFeedback: return 'استبيان ولي الأمر';
      case SurveyType.supervisorMonthly: return 'استبيان المشرفة الشهري';
      case SurveyType.studentBehavior: return 'استبيان سلوك الطلاب';
      case SurveyType.serviceQuality: return 'استبيان جودة الخدمة';
      case SurveyType.supervisorEvaluation: return 'تقييم المشرفين';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case SurveyStatus.active: return 'نشط';
      case SurveyStatus.completed: return 'مكتمل';
      case SurveyStatus.archived: return 'مؤرشف';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

enum QuestionType {
  multipleChoice,  // اختيار متعدد
  rating,         // تقييم (1-5)
  text,           // نص حر
  yesNo,          // نعم/لا
}

class SurveyQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options; // للاختيار المتعدد
  final bool isRequired;
  final int order;

  const SurveyQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.isRequired = true,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.toString().split('.').last,
      'options': options,
      'isRequired': isRequired,
      'order': order,
    };
  }

  factory SurveyQuestion.fromMap(Map<String, dynamic> map) {
    return SurveyQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: _parseQuestionType(map['type']),
      options: List<String>.from(map['options'] ?? []),
      isRequired: map['isRequired'] ?? true,
      order: map['order'] ?? 0,
    );
  }

  static QuestionType _parseQuestionType(String? type) {
    switch (type) {
      case 'multipleChoice': return QuestionType.multipleChoice;
      case 'rating': return QuestionType.rating;
      case 'text': return QuestionType.text;
      case 'yesNo': return QuestionType.yesNo;
      default: return QuestionType.text;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case QuestionType.multipleChoice: return 'اختيار متعدد';
      case QuestionType.rating: return 'تقييم';
      case QuestionType.text: return 'نص حر';
      case QuestionType.yesNo: return 'نعم/لا';
    }
  }
}

// نموذج إجابة الاستبيان
class SurveyResponse {
  final String id;
  final String surveyId;
  final String respondentId; // ID of user who responded
  final String respondentName;
  final String respondentType; // parent, supervisor, admin
  final Map<String, dynamic> answers; // questionId -> answer
  final DateTime submittedAt;
  final bool isComplete;

  const SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.respondentId,
    required this.respondentName,
    required this.respondentType,
    required this.answers,
    required this.submittedAt,
    this.isComplete = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surveyId': surveyId,
      'respondentId': respondentId,
      'respondentName': respondentName,
      'respondentType': respondentType,
      'answers': answers,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isComplete': isComplete,
    };
  }

  factory SurveyResponse.fromMap(Map<String, dynamic> map) {
    return SurveyResponse(
      id: map['id'] ?? '',
      surveyId: map['surveyId'] ?? '',
      respondentId: map['respondentId'] ?? '',
      respondentName: map['respondentName'] ?? '',
      respondentType: map['respondentType'] ?? '',
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
      submittedAt: map['submittedAt'] != null 
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isComplete: map['isComplete'] ?? true,
    );
  }
}
