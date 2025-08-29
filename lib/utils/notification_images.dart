/// مساعد لإدارة صور وأيقونات الإشعارات
class NotificationImages {
  // روابط الصور المحلية (يمكن استبدالها بروابط Firebase Storage)
  static const String _baseUrl = 'assets/notification_images/';
  static const String _iconBaseUrl = 'assets/notification_icons/';

  /// الحصول على صورة الإشعار حسب النوع
  static String getNotificationImage(String type) {
    switch (type) {
      case 'student':
        return '${_baseUrl}student_notification.png';
      case 'bus':
        return '${_baseUrl}bus_notification.png';
      case 'absence':
        return '${_baseUrl}absence_notification.png';
      case 'admin':
        return '${_baseUrl}admin_notification.png';
      case 'emergency':
        return '${_baseUrl}emergency_notification.png';
      case 'complaint':
        return '${_baseUrl}complaint_notification.png';
      default:
        return '${_baseUrl}general_notification.png';
    }
  }

  /// الحصول على أيقونة الإشعار حسب النوع
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'student':
        return '${_iconBaseUrl}student_icon.png';
      case 'bus':
        return '${_iconBaseUrl}bus_icon.png';
      case 'absence':
        return '${_iconBaseUrl}absence_icon.png';
      case 'admin':
        return '${_iconBaseUrl}admin_icon.png';
      case 'emergency':
        return '${_iconBaseUrl}emergency_icon.png';
      case 'complaint':
        return '${_iconBaseUrl}complaint_icon.png';
      default:
        return '${_iconBaseUrl}general_icon.png';
    }
  }

  /// الحصول على لون الإشعار حسب النوع
  static int getNotificationColor(String type) {
    switch (type) {
      case 'student':
        return 0xFF2196F3; // أزرق
      case 'bus':
        return 0xFFFF9800; // برتقالي
      case 'absence':
        return 0xFF9C27B0; // بنفسجي
      case 'admin':
        return 0xFF607D8B; // رمادي أزرق
      case 'emergency':
        return 0xFFF44336; // أحمر
      case 'complaint':
        return 0xFF795548; // بني
      default:
        return 0xFF4CAF50; // أخضر
    }
  }

  /// الحصول على رمز تعبيري للإشعار
  static String getNotificationEmoji(String type) {
    switch (type) {
      case 'student':
        return '👨‍🎓';
      case 'bus':
        return '🚌';
      case 'absence':
        return '📝';
      case 'admin':
        return '👨‍💼';
      case 'emergency':
        return '🚨';
      case 'complaint':
        return '📢';
      default:
        return '🔔';
    }
  }

  /// الحصول على عنوان مخصص للإشعار
  static String getCustomTitle(String type, String originalTitle) {
    final emoji = getNotificationEmoji(type);
    return '$emoji $originalTitle';
  }

  /// قائمة بجميع أنواع الإشعارات المدعومة
  static const List<String> supportedTypes = [
    'student',
    'bus',
    'absence',
    'admin',
    'emergency',
    'complaint',
    'general',
  ];

  /// التحقق من صحة نوع الإشعار
  static bool isValidType(String type) {
    return supportedTypes.contains(type);
  }

  /// الحصول على وصف نوع الإشعار
  static String getTypeDescription(String type) {
    switch (type) {
      case 'student':
        return 'إشعارات الطلاب';
      case 'bus':
        return 'إشعارات الباص';
      case 'absence':
        return 'إشعارات الغياب';
      case 'admin':
        return 'إشعارات الإدارة';
      case 'emergency':
        return 'إشعارات الطوارئ';
      case 'complaint':
        return 'إشعارات الشكاوى';
      default:
        return 'إشعارات عامة';
    }
  }

  /// إنشاء بيانات إشعار كاملة
  static Map<String, dynamic> createNotificationData({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'type': type,
      'title': getCustomTitle(type, title),
      'body': body,
      'image': getNotificationImage(type),
      'icon': getNotificationIcon(type),
      'color': getNotificationColor(type).toString(),
      'emoji': getNotificationEmoji(type),
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      ...?additionalData,
    };
  }
}

/// فئة لإدارة إعدادات الإشعارات المتقدمة
class NotificationSettings {
  /// إعدادات الصوت
  static const Map<String, String> soundSettings = {
    'student': 'student_notification.mp3',
    'bus': 'bus_notification.mp3',
    'absence': 'absence_notification.mp3',
    'admin': 'admin_notification.mp3',
    'emergency': 'emergency_notification.mp3',
    'complaint': 'complaint_notification.mp3',
    'general': 'notification_sound.mp3',
  };

  /// إعدادات الاهتزاز (بالميلي ثانية)
  static const Map<String, List<int>> vibrationPatterns = {
    'student': [0, 250, 250, 250],
    'bus': [0, 500, 200, 500],
    'absence': [0, 300, 100, 300, 100, 300],
    'admin': [0, 200, 100, 200],
    'emergency': [0, 1000, 500, 1000, 500, 1000],
    'complaint': [0, 400, 200, 400],
    'general': [0, 250, 250, 250],
  };

  /// الحصول على ملف الصوت حسب النوع
  static String getSoundFile(String type) {
    return soundSettings[type] ?? soundSettings['general']!;
  }

  /// الحصول على نمط الاهتزاز حسب النوع
  static List<int> getVibrationPattern(String type) {
    return vibrationPatterns[type] ?? vibrationPatterns['general']!;
  }

  /// إعدادات الأولوية
  static int getPriority(String type) {
    switch (type) {
      case 'emergency':
        return 5; // أولوية قصوى
      case 'bus':
      case 'student':
        return 4; // أولوية عالية جداً
      case 'admin':
        return 3; // أولوية عالية
      case 'absence':
      case 'complaint':
        return 2; // أولوية متوسطة
      default:
        return 1; // أولوية منخفضة
    }
  }

  /// تحديد ما إذا كان الإشعار يحتاج لشاشة كاملة
  static bool requiresFullScreen(String type) {
    return type == 'emergency';
  }

  /// تحديد ما إذا كان الإشعار مستمر (لا يمكن إزالته بسهولة)
  static bool isOngoing(String type) {
    return type == 'emergency';
  }
}

/// فئة لإدارة قوالب الإشعارات
class NotificationTemplates {
  /// قوالب العناوين
  static const Map<String, String> titleTemplates = {
    'student_assigned': '🚌 تم تسكين الطالب',
    'student_unassigned': '🚫 تم إلغاء تسكين الطالب',
    'student_boarded': '🚌 ركب الطالب الباص',
    'student_alighted': '🏠 نزل الطالب من الباص',
    'absence_requested': '📝 طلب غياب جديد',
    'absence_approved': '✅ تم قبول طلب الغياب',
    'absence_rejected': '❌ تم رفض طلب الغياب',
    'complaint_new': '📢 شكوى جديدة',
    'complaint_response': '💬 رد على الشكوى',
    'emergency_alert': '🚨 حالة طوارئ',
    'trip_started': '🚌 بدأت الرحلة',
    'trip_completed': '✅ انتهت الرحلة',
    'trip_delayed': '⏰ تأخير في الرحلة',
  };

  /// الحصول على عنوان من القالب
  static String getTitle(String templateKey, [Map<String, String>? variables]) {
    String title = titleTemplates[templateKey] ?? '🔔 إشعار جديد';
    
    if (variables != null) {
      variables.forEach((key, value) {
        title = title.replaceAll('{$key}', value);
      });
    }
    
    return title;
  }

  /// قوالب المحتوى
  static String getBodyTemplate(String templateKey) {
    switch (templateKey) {
      case 'student_assigned':
        return 'تم تسكين {studentName} في الباص رقم {busId} - خط السير: {busRoute}';
      case 'student_boarded':
        return '{studentName} ركب الباص في الساعة {time}';
      case 'absence_requested':
        return 'طلب غياب للطالب {studentName} بتاريخ {date} - السبب: {reason}';
      default:
        return 'إشعار جديد من تطبيق MyBus';
    }
  }
}
