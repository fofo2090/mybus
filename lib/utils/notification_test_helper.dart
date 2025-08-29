import 'package:flutter/foundation.dart';
import '../services/unified_notification_service.dart';

/// مساعد اختبار الإشعارات
/// يحتوي على دوال لاختبار جميع أنواع الإشعارات
class NotificationTestHelper {
  static final UnifiedNotificationService _notificationService = UnifiedNotificationService();

  /// اختبار شامل لجميع أنواع الإشعارات
  static Future<void> runFullNotificationTest() async {
    try {
      debugPrint('🧪 بدء اختبار شامل للإشعارات...');

      // اختبار الإشعار العام
      await _testGeneralNotification();
      await Future.delayed(const Duration(seconds: 2));

      // اختبار إشعار الطلاب
      await _testStudentNotification();
      await Future.delayed(const Duration(seconds: 2));

      // اختبار إشعار الباص
      await _testBusNotification();
      await Future.delayed(const Duration(seconds: 2));

      // اختبار إشعار الطوارئ
      await _testEmergencyNotification();
      await Future.delayed(const Duration(seconds: 2));

      // اختبار إشعار الإدارة
      await _testAdminNotification();

      debugPrint('✅ تم إكمال اختبار الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الإشعارات: $e');
    }
  }

  /// اختبار الإشعار العام
  static Future<void> _testGeneralNotification() async {
    await _notificationService.showLocalNotification(
      title: '📢 إشعار عام',
      body: 'هذا إشعار عام من تطبيق كيدز باص',
      channelId: 'mybus_notifications',
      data: {
        'type': 'general',
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ تم إرسال الإشعار العام');
  }

  /// اختبار إشعار الطلاب
  static Future<void> _testStudentNotification() async {
    await _notificationService.showLocalNotification(
      title: '👨‍🎓 إشعار طالب',
      body: 'تم تسكين الطالب أحمد محمد في الباص رقم 101',
      channelId: 'student_notifications',
      data: {
        'type': 'student',
        'studentName': 'أحمد محمد',
        'busNumber': '101',
        'action': 'assigned',
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ تم إرسال إشعار الطالب');
  }

  /// اختبار إشعار الباص
  static Future<void> _testBusNotification() async {
    await _notificationService.showLocalNotification(
      title: '🚌 إشعار الباص',
      body: 'ركب الطالب سارة أحمد الباص رقم 102 في الساعة 7:30 ص',
      channelId: 'bus_notifications',
      data: {
        'type': 'bus',
        'studentName': 'سارة أحمد',
        'busNumber': '102',
        'action': 'boarded',
        'time': '7:30 ص',
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ تم إرسال إشعار الباص');
  }

  /// اختبار إشعار الطوارئ
  static Future<void> _testEmergencyNotification() async {
    await _notificationService.showLocalNotification(
      title: '🚨 تنبيه طوارئ',
      body: 'تأخير في وصول الباص رقم 103 بسبب الازدحام المروري',
      channelId: 'emergency_notifications',
      data: {
        'type': 'emergency',
        'busNumber': '103',
        'reason': 'traffic',
        'severity': 'medium',
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ تم إرسال إشعار الطوارئ');
  }

  /// اختبار إشعار الإدارة
  static Future<void> _testAdminNotification() async {
    await _notificationService.showLocalNotification(
      title: '👨‍💼 إشعار إداري',
      body: 'تم إنشاء تقرير جديد للحضور والغياب لهذا الأسبوع',
      channelId: 'admin_notifications',
      data: {
        'type': 'admin',
        'reportType': 'attendance',
        'period': 'weekly',
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ تم إرسال الإشعار الإداري');
  }

  /// اختبار إشعار مع صورة
  static Future<void> testNotificationWithImage() async {
    await _notificationService.showLocalNotification(
      title: '📸 إشعار مع صورة',
      body: 'هذا إشعار يحتوي على صورة للاختبار',
      channelId: 'mybus_notifications',
      imageUrl: 'https://via.placeholder.com/300x200/1E88E5/FFFFFF?text=Kids+Bus',
      data: {
        'type': 'image_test',
        'hasImage': 'true',
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('✅ تم إرسال إشعار مع صورة');
  }

  /// اختبار سريع للإشعارات
  static Future<void> quickTest() async {
    await _notificationService.testNotification();
  }

  /// اختبار إشعار ترحيب
  static Future<void> testWelcomeNotification() async {
    await _notificationService.sendWelcomeNotification('المستخدم التجريبي');
  }

  /// طباعة معلومات النظام
  static void printSystemInfo() {
    debugPrint('📱 معلومات نظام الإشعارات:');
    debugPrint('- الخدمة مهيأة: ${_notificationService.isInitialized}');
    debugPrint('- FCM Token: ${_notificationService.currentToken?.substring(0, 20) ?? 'غير متوفر'}...');
    debugPrint('- عدد القنوات: ${_notificationService.channels.length}');
    
    for (final channel in _notificationService.channels) {
      debugPrint('  - ${channel.name} (${channel.id})');
    }
  }
}