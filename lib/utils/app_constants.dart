import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'كيدز باص';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'كيدز باص - تطبيق تتبع الطلاب في الباص المدرسي';

  // Colors
  static const int primaryColorValue = 0xFF1E88E5;
  static const Color primaryColor = Color(primaryColorValue);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';
  static const String tripsCollection = 'trips';
  static const String notificationsCollection = 'notifications';

  // User Types
  static const String parentUserType = 'parent';
  static const String supervisorUserType = 'supervisor';
  static const String adminUserType = 'admin';

  // Student Status
  static const String homeStatus = 'home';
  static const String onBusStatus = 'onBus';
  static const String atSchoolStatus = 'atSchool';

  // Trip Types
  static const String toSchoolTrip = 'toSchool';
  static const String fromSchoolTrip = 'fromSchool';

  // Trip Actions
  static const String boardBusAction = 'boardBus';
  static const String leaveBusAction = 'leaveBus';

  // Notification Types
  static const String studentBoardedNotification = 'studentBoarded';
  static const String studentLeftNotification = 'studentLeft';
  static const String tripStartedNotification = 'tripStarted';
  static const String tripEndedNotification = 'tripEnded';
  static const String generalNotification = 'general';

  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int minPhoneLength = 10;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultButtonHeight = 50.0;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Error Messages
  static const String networkError = 'خطأ في الاتصال بالإنترنت';
  static const String unknownError = 'حدث خطأ غير متوقع';
  static const String authError = 'خطأ في المصادقة';
  static const String permissionError = 'ليس لديك صلاحية للوصول';

  // Success Messages
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String registerSuccess = 'تم إنشاء الحساب بنجاح';
  static const String updateSuccess = 'تم التحديث بنجاح';
  static const String deleteSuccess = 'تم الحذف بنجاح';

  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String parentHomeRoute = '/parent';
  static const String supervisorHomeRoute = '/supervisor';
  static const String adminHomeRoute = '/admin';
  static const String qrScannerRoute = '/supervisor/qr-scanner';
  static const String studentActivityRoute = '/parent/student-activity';
  static const String notificationsRoute = '/parent/notifications';
  static const String studentManagementRoute = '/admin/students';
  static const String addStudentRoute = '/admin/students/add';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userTypeKey = 'user_type';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String notificationsEnabledKey = 'notifications_enabled';

  // Default Values
  static const String defaultSchoolName = 'النيل الدوليه بطيبه';
  static const String defaultBusRoute = 'الخط الأول';
  static const String defaultSupervisorName = 'المشرف';

  // Limits
  static const int maxStudentsPerBus = 50;
  static const int maxNotificationsToShow = 100;
  static const int maxTripsToShow = 50;

  // Time Constants
  static const int splashDuration = 3; // seconds
  static const int notificationTimeout = 5; // seconds
  static const int cacheTimeout = 300; // seconds (5 minutes)

  // QR Code Settings
  static const double qrCodeSize = 300.0;
  static const int qrCodeBorderLength = 30;
  static const int qrCodeBorderWidth = 10;

  // Animation Durations
  static const int shortAnimationDuration = 300; // milliseconds
  static const int mediumAnimationDuration = 500; // milliseconds
  static const int longAnimationDuration = 1000; // milliseconds

  // Educational Stages and Grades
  static const List<String> educationalStages = [
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

  // Legacy support for existing code
  static const List<String> studentGrades = educationalStages;
}

class AppStrings {
  // Arabic Strings
  static const String appNameAr = 'كيدز باص';
  static const String welcomeAr = 'مرحباً بك';
  static const String loginAr = 'تسجيل الدخول';
  static const String registerAr = 'إنشاء حساب';
  static const String emailAr = 'البريد الإلكتروني';
  static const String passwordAr = 'كلمة المرور';
  static const String nameAr = 'الاسم';
  static const String phoneAr = 'رقم الهاتف';
  static const String studentNameAr = 'اسم الطالب';
  static const String gradeAr = 'الصف';
  static const String schoolAr = 'المدرسة';
  static const String busRouteAr = 'خط الباص';
  static const String parentAr = 'ولي الأمر';
  static const String supervisorAr = 'المشرف';
  static const String adminAr = 'الإدارة';
  static const String homeAr = 'في المنزل';
  static const String onBusAr = 'في الباص';
  static const String atSchoolAr = 'في المدرسة';
  static const String boardedAr = 'ركب الباص';
  static const String leftAr = 'نزل من الباص';
  static const String notificationsAr = 'الإشعارات';
  static const String settingsAr = 'الإعدادات';
  static const String logoutAr = 'تسجيل الخروج';
  static const String saveAr = 'حفظ';
  static const String cancelAr = 'إلغاء';
  static const String deleteAr = 'حذف';
  static const String editAr = 'تعديل';
  static const String addAr = 'إضافة';
  static const String searchAr = 'البحث';
  static const String noDataAr = 'لا توجد بيانات';
  static const String loadingAr = 'جاري التحميل...';
  static const String errorAr = 'خطأ';
  static const String successAr = 'نجح';
  static const String confirmAr = 'تأكيد';
  static const String yesAr = 'نعم';
  static const String noAr = 'لا';

  // English Strings (for development/debugging)
  static const String appNameEn = 'KidsBus';
  static const String welcomeEn = 'Welcome';
  static const String loginEn = 'Login';
  static const String registerEn = 'Register';
  static const String emailEn = 'Email';
  static const String passwordEn = 'Password';
  static const String nameEn = 'Name';
  static const String phoneEn = 'Phone';
  static const String studentNameEn = 'Student Name';
  static const String gradeEn = 'Grade';
  static const String schoolEn = 'School';
  static const String busRouteEn = 'Bus Route';
  static const String parentEn = 'Parent';
  static const String supervisorEn = 'Supervisor';
  static const String adminEn = 'Admin';
  static const String homeEn = 'At Home';
  static const String onBusEn = 'On Bus';
  static const String atSchoolEn = 'At School';
  static const String boardedEn = 'Boarded Bus';
  static const String leftEn = 'Left Bus';
  static const String notificationsEn = 'Notifications';
  static const String settingsEn = 'Settings';
  static const String logoutEn = 'Logout';
  static const String saveEn = 'Save';
  static const String cancelEn = 'Cancel';
  static const String deleteEn = 'Delete';
  static const String editEn = 'Edit';
  static const String addEn = 'Add';
  static const String searchEn = 'Search';
  static const String noDataEn = 'No Data';
  static const String loadingEn = 'Loading...';
  static const String errorEn = 'Error';
  static const String successEn = 'Success';
  static const String confirmEn = 'Confirm';
  static const String yesEn = 'Yes';
  static const String noEn = 'No';
}
