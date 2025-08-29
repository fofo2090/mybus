/// إعدادات الإشعارات المركزية
/// يحتوي على جميع الثوابت والإعدادات المتعلقة بالإشعارات
class NotificationConfig {
  // معرفات القنوات
  static const String mainChannelId = 'mybus_notifications';
  static const String studentChannelId = 'student_notifications';
  static const String busChannelId = 'bus_notifications';
  static const String emergencyChannelId = 'emergency_notifications';
  static const String adminChannelId = 'admin_notifications';

  // أسماء القنوات
  static const String mainChannelName = 'كيدز باص - الإشعارات العامة';
  static const String studentChannelName = 'إشعارات الطلاب';
  static const String busChannelName = 'إشعارات الباص';
  static const String emergencyChannelName = 'تنبيهات الطوارئ';
  static const String adminChannelName = 'إشعارات الإدارة';

  // أوصاف القنوات
  static const String mainChannelDescription = 'إشعارات عامة من تطبيق كيدز باص للنقل المدرسي';
  static const String studentChannelDescription = 'إشعارات متعلقة بالطلاب وأنشطتهم';
  static const String busChannelDescription = 'إشعارات ركوب ونزول الباص';
  static const String emergencyChannelDescription = 'تنبيهات طوارئ مهمة وعاجلة';
  static const String adminChannelDescription = 'إشعارات إدارية للمسؤولين';

  // أصوات الإشعارات
  static const String defaultSound = 'notification_sound';
  static const String emergencySound = 'emergency_sound';
  static const String welcomeSound = 'welcome_sound';

  // ألوان الإشعارات
  static const int primaryColor = 0xFF1E88E5;
  static const int studentColor = 0xFF4CAF50;
  static const int busColor = 0xFFFF9800;
  static const int emergencyColor = 0xFFF44336;
  static const int adminColor = 0xFF9C27B0;

  // أيقونات الإشعارات
  static const String defaultIcon = '@drawable/ic_notification';
  static const String largeIcon = '@mipmap/launcher_icon';

  // إعدادات الاهتزاز
  static const List<int> defaultVibrationPattern = [0, 250, 250, 250];
  static const List<int> emergencyVibrationPattern = [0, 500, 200, 500, 200, 500];

  // إعدادات الأولوية
  static const String highPriority = 'high';
  static const String maxPriority = 'max';
  static const String defaultPriority = 'default';

  // إعدادات الرؤية
  static const String publicVisibility = 'public';
  static const String privateVisibility = 'private';

  // مدة عرض الإشعارات (بالثواني)
  static const int defaultDuration = 5;
  static const int emergencyDuration = 10;
  static const int welcomeDuration = 3;

  // حد أقصى لعدد الإشعارات المحفوظة
  static const int maxStoredNotifications = 50;

  // مدة انتهاء صلاحية تسجيل الدخول (بالأيام)
  static const int loginExpirationDays = 30;

  // إعدادات FCM
  static const String fcmSenderId = '1234567890'; // يجب تحديثه بالرقم الصحيح
  static const String fcmServerKey = 'YOUR_SERVER_KEY'; // يجب تحديثه بالمفتاح الصحيح

  // مسارات الأصوات
  static const String soundsPath = 'assets/sounds/';
  static const String imagesPath = 'assets/images/';

  // أنواع الإشعارات
  enum NotificationType {
    general,
    student,
    bus,
    emergency,
    admin,
    welcome,
    test,
  }

  // حالات الإشعارات
  enum NotificationStatus {
    pending,
    sent,
    delivered,
    read,
    failed,
  }

  // مستويات الأولوية
  enum Priority {
    low,
    normal,
    high,
    max,
  }

  /// الحصول على معرف القناة حسب النوع
  static String getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.student:
        return studentChannelId;
      case NotificationType.bus:
        return busChannelId;
      case NotificationType.emergency:
        return emergencyChannelId;
      case NotificationType.admin:
        return adminChannelId;
      default:
        return mainChannelId;
    }
  }

  /// الحصول على اسم القناة حسب النوع
  static String getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.student:
        return studentChannelName;
      case NotificationType.bus:
        return busChannelName;
      case NotificationType.emergency:
        return emergencyChannelName;
      case NotificationType.admin:
        return adminChannelName;
      default:
        return mainChannelName;
    }
  }

  /// الحصول على وصف القناة حسب النوع
  static String getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.student:
        return studentChannelDescription;
      case NotificationType.bus:
        return busChannelDescription;
      case NotificationType.emergency:
        return emergencyChannelDescription;
      case NotificationType.admin:
        return adminChannelDescription;
      default:
        return mainChannelDescription;
    }
  }

  /// الحصول على لون الإشعار حسب النوع
  static int getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.student:
        return studentColor;
      case NotificationType.bus:
        return busColor;
      case NotificationType.emergency:
        return emergencyColor;
      case NotificationType.admin:
        return adminColor;
      default:
        return primaryColor;
    }
  }

  /// الحصول على صوت الإشعار حسب النوع
  static String getNotificationSound(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return emergencySound;
      case NotificationType.welcome:
        return welcomeSound;
      default:
        return defaultSound;
    }
  }

  /// الحصول على نمط الاهتزاز حسب النوع
  static List<int> getVibrationPattern(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return emergencyVibrationPattern;
      default:
        return defaultVibrationPattern;
    }
  }

  /// التحقق من صحة معرف القناة
  static bool isValidChannelId(String channelId) {
    return [
      mainChannelId,
      studentChannelId,
      busChannelId,
      emergencyChannelId,
      adminChannelId,
    ].contains(channelId);
  }

  /// إنشاء معرف فريد للإشعار
  static String generateNotificationId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// تحويل نوع الإشعار إلى نص
  static String notificationTypeToString(NotificationType type) {
    return type.toString().split('.').last;
  }

  /// تحويل النص إلى نوع إشعار
  static NotificationType? stringToNotificationType(String typeString) {
    for (NotificationType type in NotificationType.values) {
      if (notificationTypeToString(type) == typeString) {
        return type;
      }
    }
    return null;
  }
}