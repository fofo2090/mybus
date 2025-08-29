class AppConstants {
  // Bus Routes
  static const List<String> busRoutes = [
    'خط العواميه',
    'خط التليفزيون', 
    'خط البياضية',
    'خط شرق السكة',
    'خط الشمال',
    'خط الجنوب',
    'خط الشرق',
    'خط الغرب',
    'خط الوسط',
  ];

  // Educational Stages and Grades
  static const List<String> studentGrades = [
    'كي جي 1',
    'كي جي 2',
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
    'الصف الثالث الإعدادي',
  ];

  // Educational Stages Categories
  static const Map<String, List<String>> educationalStagesCategories = {
    'مرحلة رياض الأطفال': [
      'كي جي 1',
      'كي جي 2',
    ],
    'المرحلة الابتدائية': [
      'الصف الأول الابتدائي',
      'الصف الثاني الابتدائي',
      'الصف الثالث الابتدائي',
      'الصف الرابع الابتدائي',
      'الصف الخامس الابتدائي',
      'الصف السادس الابتدائي',
    ],
    'المرحلة الإعدادية': [
      'الصف الأول الإعدادي',
      'الصف الثاني الإعدادي',
      'الصف الثالث الإعدادي',
    ],
  };

  // School Names
  static const List<String> schoolNames = [
    'النيل الدوليه بطيبه',
    'المستقبل بطيبه',
    'المستقبل الدوليه بالطود',
    'المدرسه التجريبى بطيبه',
  ];

  // App Colors
  static const int primaryColorValue = 0xFF1E88E5;
  static const int secondaryColorValue = 0xFFFF9800;
  static const int successColorValue = 0xFF4CAF50;
  static const int errorColorValue = 0xFFF44336;
  static const int warningColorValue = 0xFFFF9800;

  // App Settings
  static const String appName = 'كيدز باص';
  static const String appVersion = '1.0.0';
  static const int maxStudentsPerBus = 50;
  static const int minStudentsPerBus = 1;
  static const int maxBusCapacity = 60;
  static const int minBusCapacity = 10;

  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  static const int qrCodeLength = 8;

  // Time Settings
  static const int sessionTimeoutMinutes = 30;
  static const int notificationRetentionDays = 30;
  static const int tripHistoryRetentionDays = 90;
}
