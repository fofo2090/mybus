// أنواع النسخ الاحتياطية
enum BackupType {
  manual,
  automatic,
  scheduled,
  emergency,
}

// حالات النسخة الاحتياطية
enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
  corrupted,
}

// مستويات الأولوية
enum BackupPriority {
  low,
  normal,
  high,
  critical,
}

/// إعدادات النسخ الاحتياطي
class BackupConfig {
  // إعدادات النسخ التلقائي
  static const int defaultBackupIntervalHours = 24;
  static const int maxBackupsToKeep = 10;
  static const int backupTimeoutMinutes = 10;
  
  // أسماء المفاتيح في SharedPreferences
  static const String autoBackupEnabledKey = 'auto_backup_enabled';
  static const String lastBackupDateKey = 'last_backup_date';
  static const String backupIntervalKey = 'backup_interval_hours';
  static const String backupCountKey = 'total_backups_created';
  
  // قائمة المجموعات المراد نسخها
  static const List<String> collectionsToBackup = [
    'students',
    'users',
    'buses',
    'supervisor_assignments',
    'absences',
    'complaints',
    'surveys',
    'survey_responses',
    'notifications',
    'trips',
    'behavior_evaluations',
    'settings',
    'emergency_contacts',
    'announcements',
  ];
  
  // إعدادات الأمان
  static const bool requireConfirmationForRestore = true;
  static const bool enableBackupEncryption = false; // للمستقبل
  static const int maxRestoreAttempts = 3;
  
  // إعدادات الأداء
  static const int batchSize = 100; // عدد المستندات في كل دفعة
  static const int maxConcurrentOperations = 5;
  static const Duration operationTimeout = Duration(minutes: 5);
  
  // إعدادات التنبيهات
  static const bool notifyOnBackupSuccess = true;
  static const bool notifyOnBackupFailure = true;
  static const bool notifyOnAutoBackup = false;
  
  // إعدادات التخزين
  static const String backupCollectionName = 'backups';
  static const String backupMetadataCollection = 'backup_metadata';
  

  
  /// الحصول على وصف نوع النسخة
  static String getBackupTypeDescription(BackupType type) {
    switch (type) {
      case BackupType.manual:
        return 'نسخة يدوية';
      case BackupType.automatic:
        return 'نسخة تلقائية';
      case BackupType.scheduled:
        return 'نسخة مجدولة';
      case BackupType.emergency:
        return 'نسخة طوارئ';
    }
  }
  
  /// الحصول على وصف حالة النسخة
  static String getBackupStatusDescription(BackupStatus status) {
    switch (status) {
      case BackupStatus.pending:
        return 'في الانتظار';
      case BackupStatus.inProgress:
        return 'قيد التنفيذ';
      case BackupStatus.completed:
        return 'مكتملة';
      case BackupStatus.failed:
        return 'فشلت';
      case BackupStatus.corrupted:
        return 'تالفة';
    }
  }
  
  /// التحقق من صحة إعدادات النسخ
  static bool validateBackupSettings({
    required int intervalHours,
    required int maxBackups,
  }) {
    return intervalHours >= 1 && 
           intervalHours <= 168 && // أسبوع كحد أقصى
           maxBackups >= 1 && 
           maxBackups <= 50;
  }
  
  /// الحصول على الفترات المتاحة للنسخ التلقائي
  static Map<int, String> getAvailableIntervals() {
    return {
      1: 'كل ساعة',
      6: 'كل 6 ساعات',
      12: 'كل 12 ساعة',
      24: 'يومياً',
      48: 'كل يومين',
      72: 'كل 3 أيام',
      168: 'أسبوعياً',
    };
  }
  
  /// الحصول على أحجام النسخ المتوقعة
  static Map<String, String> getExpectedBackupSizes() {
    return {
      'صغير (< 100 طالب)': '< 1 MB',
      'متوسط (100-500 طالب)': '1-5 MB',
      'كبير (500-1000 طالب)': '5-10 MB',
      'كبير جداً (> 1000 طالب)': '> 10 MB',
    };
  }
  
  /// إعدادات الضغط والتحسين
  static const bool enableCompression = true;
  static const bool removeEmptyFields = true;
  static const bool optimizeForSize = true;
  
  /// إعدادات الشبكة
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);
}
