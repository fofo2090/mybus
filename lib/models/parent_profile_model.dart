class ParentProfileModel {
  final String id;
  final String fullName;
  final String address;
  final String occupation;
  final String fatherPhone;
  final String motherPhone;
  final String email;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentProfileModel({
    required this.id,
    required this.fullName,
    required this.address,
    required this.occupation,
    required this.fatherPhone,
    required this.motherPhone,
    required this.email,
    required this.isProfileComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentProfileModel.fromMap(Map<String, dynamic> map) {
    return ParentProfileModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      occupation: map['occupation'] ?? '',
      fatherPhone: map['fatherPhone'] ?? '',
      motherPhone: map['motherPhone'] ?? '',
      email: map['email'] ?? '',
      isProfileComplete: map['isProfileComplete'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'address': address,
      'occupation': occupation,
      'fatherPhone': fatherPhone,
      'motherPhone': motherPhone,
      'email': email,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ParentProfileModel copyWith({
    String? id,
    String? fullName,
    String? address,
    String? occupation,
    String? fatherPhone,
    String? motherPhone,
    String? email,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      motherPhone: motherPhone ?? this.motherPhone,
      email: email ?? this.email,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasRequiredData {
    return fullName.isNotEmpty &&
           address.isNotEmpty &&
           occupation.isNotEmpty &&
           fatherPhone.isNotEmpty &&
           motherPhone.isNotEmpty;
  }

  String get displayName {
    return fullName.isNotEmpty ? fullName : email;
  }

  String get initials {
    if (fullName.isEmpty) return 'و';
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}';
    }
    return fullName[0];
  }
}
