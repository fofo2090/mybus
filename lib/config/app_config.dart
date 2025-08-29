import 'package:flutter/foundation.dart';

/// إعدادات التطبيق والبيئة
/// Application and environment configuration
class AppConfig {
  // إعدادات البيئة
  static const bool isProduction = kReleaseMode;
  static const bool isDevelopment = kDebugMode;
  
  // إعدادات Firebase (يجب نقلها إلى متغيرات البيئة في الإنتاج)
  static const String firebaseProjectId = 'mybus-5a992';
  static const String firebaseStorageBucket = 'mybus-5a992.firebasestorage.app';
  static const String firebaseAuthDomain = 'mybus-5a992.firebaseapp.com';
  
  // إعدادات الأمان
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxFileUploadSize = 5 * 1024 * 1024; // 5MB
  
  // إعدادات التطبيق
  static const String appName = 'KidsBus';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@kidsbus.com';
  static const String supportPhone = '+966501234567';
  
  // إعدادات قاعدة البيانات
  static const int maxQueryLimit = 100;
  static const Duration cacheTimeout = Duration(minutes: 30);
  static const int maxRetryAttempts = 3;
  
  // إعدادات الإشعارات
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSMSNotifications = false;
  
  // إعدادات التشفير
  static const String encryptionAlgorithm = 'AES-256';
  static const int tokenExpiryHours = 24;
  
  // إعدادات التحقق
  static const int otpLength = 6;
  static const Duration otpExpiry = Duration(minutes: 5);
  static const int maxOtpAttempts = 3;
  
  // إعدادات الملفات
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // إعدادات الشبكة
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxConcurrentRequests = 10;
  
  // إعدادات التسجيل
  static const bool enableLogging = true;
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = false; // معطل لحماية الخصوصية
  
  // إعدادات الأداء
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration backgroundTaskTimeout = Duration(minutes: 5);
  
  // إعدادات الأمان المتقدمة
  static const bool enableBiometricAuth = true;
  static const bool enableDeviceBinding = true;
  static const bool enableCertificatePinning = true;
  
  // إعدادات المراقبة
  static const bool enableSecurityMonitoring = true;
  static const bool enablePerformanceMonitoring = true;
  static const Duration monitoringInterval = Duration(minutes: 1);
  
  /// الحصول على إعدادات البيئة الحالية
  /// Get current environment settings
  static Map<String, dynamic> getCurrentEnvironment() {
    return {
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'appName': appName,
      'appVersion': appVersion,
      'firebaseProjectId': firebaseProjectId,
      'enableLogging': enableLogging,
      'enableSecurityMonitoring': enableSecurityMonitoring,
    };
  }
  
  /// التحقق من صحة الإعدادات
  /// Validate configuration
  static bool validateConfig() {
    try {
      // التحقق من الإعدادات الأساسية
      if (appName.isEmpty || appVersion.isEmpty) return false;
      if (firebaseProjectId.isEmpty) return false;
      if (maxLoginAttempts <= 0) return false;
      if (maxFileUploadSize <= 0) return false;
      
      return true;
    } catch (e) {
      debugPrint('❌ Configuration validation failed: $e');
      return false;
    }
  }
  
  /// الحصول على إعدادات الأمان
  /// Get security settings
  static Map<String, dynamic> getSecuritySettings() {
    return {
      'maxLoginAttempts': maxLoginAttempts,
      'loginCooldown': loginCooldown.inMinutes,
      'sessionTimeout': sessionTimeout.inHours,
      'enableBiometricAuth': enableBiometricAuth,
      'enableDeviceBinding': enableDeviceBinding,
      'enableCertificatePinning': enableCertificatePinning,
      'enableSecurityMonitoring': enableSecurityMonitoring,
    };
  }
  
  /// الحصول على إعدادات الأداء
  /// Get performance settings
  static Map<String, dynamic> getPerformanceSettings() {
    return {
      'maxCacheSize': maxCacheSize,
      'cacheTimeout': cacheTimeout.inMinutes,
      'networkTimeout': networkTimeout.inSeconds,
      'maxConcurrentRequests': maxConcurrentRequests,
      'backgroundTaskTimeout': backgroundTaskTimeout.inMinutes,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
    };
  }
}
