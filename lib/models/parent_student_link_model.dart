class ParentStudentLinkModel {
  final String id;
  final String parentId;
  final String parentEmail;
  final String parentPhone;
  final List<String> studentIds;
  final bool isLinked;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentStudentLinkModel({
    required this.id,
    required this.parentId,
    required this.parentEmail,
    required this.parentPhone,
    required this.studentIds,
    required this.isLinked,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
      'studentIds': studentIds,
      'isLinked': isLinked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ParentStudentLinkModel.fromMap(Map<String, dynamic> map) {
    return ParentStudentLinkModel(
      id: map['id'] ?? '',
      parentId: map['parentId'] ?? '',
      parentEmail: map['parentEmail'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
      isLinked: map['isLinked'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is String 
              ? DateTime.parse(map['createdAt']) 
              : (map['createdAt'].toDate() as DateTime))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is String 
              ? DateTime.parse(map['updatedAt']) 
              : (map['updatedAt'].toDate() as DateTime))
          : DateTime.now(),
    );
  }

  ParentStudentLinkModel copyWith({
    String? id,
    String? parentId,
    String? parentEmail,
    String? parentPhone,
    List<String>? studentIds,
    bool? isLinked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentStudentLinkModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      studentIds: studentIds ?? this.studentIds,
      isLinked: isLinked ?? this.isLinked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
