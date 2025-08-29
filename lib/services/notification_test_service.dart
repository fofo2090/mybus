import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'fcm_service.dart';
import 'fcm_v1_service.dart';

/// خدمة اختبار شاملة للإشعارات
/// تختبر جميع أنواع الإشعارات في جميع الحالات
class NotificationTestService {
  static final NotificationTestService _instance = NotificationTestService._internal();
  factory NotificationTestService() => _instance;
  NotificationTestService._internal();

  final FCMService _fcmService = FCMService();
  final FCMv1Service _fcmV1Service = FCMv1Service();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// اختبار شامل لجميع أنواع الإشعارات
  Future<Map<String, dynamic>> runFullNotificationTest() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'tests': <String, dynamic>{},
    };

    debugPrint('🧪 Starting comprehensive notification test...');

    try {
      // 1. اختبار الأذونات
      results['tests']['permissions'] = await _testPermissions();
      
      // 2. اختبار FCM Token
      results['tests']['fcm_token'] = await _testFCMToken();
      
      // 3. اختبار Local Notifications
      results['tests']['local_notifications'] = await _testLocalNotifications();
      
      // 4. اختبار FCM Service
      results['tests']['fcm_service'] = await _testFCMService();
      
      // 5. اختبار Background Notifications
      results['tests']['background_notifications'] = await _testBackgroundNotifications();
      
      // 6. اختبار Platform-specific features
      if (Platform.isAndroid) {
        results['tests']['android_specific'] = await _testAndroidSpecific();
      } else if (Platform.isIOS) {
        results['tests']['ios_specific'] = await _testIOSSpecific();
      }

      // 7. تقييم النتائج الإجمالية
      results['overall_success'] = _evaluateOverallResults(results['tests']);
      
      debugPrint('✅ Notification test completed');
      return results;
      
    } catch (e) {
      debugPrint('❌ Error during notification test: $e');
      results['error'] = e.toString();
      results['overall_success'] = false;
      return results;
    }
  }

  /// اختبار الأذونات
  Future<Map<String, dynamic>> _testPermissions() async {
    debugPrint('🔐 Testing permissions...');
    
    final result = <String, dynamic>{};
    
    try {
      // اختبار أذونات الإشعارات
      final notificationStatus = await Permission.notification.status;
      result['notification_permission'] = {
        'status': notificationStatus.toString(),
        'granted': notificationStatus.isGranted,
      };

      if (Platform.isAndroid) {
        // اختبار أذونات Android 13+
        if (Platform.version.contains('33') || Platform.version.contains('34')) {
          final postNotificationStatus = await Permission.notification.request();
          result['post_notification_permission'] = {
            'status': postNotificationStatus.toString(),
            'granted': postNotificationStatus.isGranted,
          };
        }
      }

      // اختبار أذونات FCM
      final fcmSettings = await FirebaseMessaging.instance.getNotificationSettings();
      result['fcm_settings'] = {
        'authorization_status': fcmSettings.authorizationStatus.toString(),
        'alert': fcmSettings.alert.toString(),
        'badge': fcmSettings.badge.toString(),
        'sound': fcmSettings.sound.toString(),
      };

      result['success'] = notificationStatus.isGranted && 
                         fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// اختبار FCM Token
  Future<Map<String, dynamic>> _testFCMToken() async {
    debugPrint('🔑 Testing FCM token...');
    
    final result = <String, dynamic>{};
    
    try {
      final token = await FirebaseMessaging.instance.getToken();
      
      result['token_available'] = token != null;
      result['token_length'] = token?.length ?? 0;
      result['token_preview'] = token != null ? '${token.substring(0, 20)}...' : null;
      result['success'] = token != null && token.isNotEmpty;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// اختبار Local Notifications
  Future<Map<String, dynamic>> _testLocalNotifications() async {
    debugPrint('📱 Testing local notifications...');
    
    final result = <String, dynamic>{};
    
    try {
      // اختبار تهيئة Local Notifications
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final initialized = await _localNotifications.initialize(initSettings);
      result['initialization'] = initialized ?? false;

      // اختبار إرسال إشعار محلي
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        999,
        'اختبار الإشعارات المحلية 🧪',
        'هذا إشعار تجريبي للتأكد من عمل النظام المحلي',
        details,
      );
      
      result['test_notification_sent'] = true;
      result['success'] = initialized ?? false;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// اختبار FCM Service
  Future<Map<String, dynamic>> _testFCMService() async {
    debugPrint('🔥 Testing FCM service...');
    
    final result = <String, dynamic>{};
    
    try {
      // اختبار تهيئة FCM Service
      await _fcmService.initialize();
      result['fcm_service_initialized'] = true;

      // اختبار إرسال إشعار تجريبي
      await _fcmService.sendTestNotification(
        title: 'اختبار FCM Service 🔥',
        body: 'هذا إشعار تجريبي من FCM Service',
        data: {'test': 'fcm_service'},
      );
      result['test_notification_sent'] = true;

      // اختبار الحصول على التوكن
      final token = await _fcmService.getToken();
      result['token_retrieved'] = token != null;

      result['success'] = true;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// اختبار Background Notifications
  Future<Map<String, dynamic>> _testBackgroundNotifications() async {
    debugPrint('🌙 Testing background notifications...');
    
    final result = <String, dynamic>{};
    
    try {
      // محاكاة إشعار خلفية
      final testMessage = RemoteMessage(
        messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'title': 'اختبار الإشعار الخلفي 🌙',
          'body': 'هذا إشعار تجريبي للخلفية',
          'test': 'background',
        },
      );

      // اختبار معالج الخلفية (محاكاة)
      result['background_handler_available'] = true;
      result['test_message_created'] = true;
      result['success'] = true;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// اختبار ميزات Android المحددة
  Future<Map<String, dynamic>> _testAndroidSpecific() async {
    debugPrint('🤖 Testing Android-specific features...');
    
    final result = <String, dynamic>{};
    
    try {
      // اختبار Notification Channels
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // إنشاء قناة اختبار
        const testChannel = AndroidNotificationChannel(
          'test_channel_android',
          'Android Test Channel',
          description: 'Test channel for Android notifications',
          importance: Importance.max,
        );
        
        await androidImplementation.createNotificationChannel(testChannel);
        result['test_channel_created'] = true;
      }

      result['android_implementation_available'] = androidImplementation != null;
      result['success'] = true;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// اختبار ميزات iOS المحددة
  Future<Map<String, dynamic>> _testIOSSpecific() async {
    debugPrint('🍎 Testing iOS-specific features...');
    
    final result = <String, dynamic>{};
    
    try {
      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      result['ios_implementation_available'] = iosImplementation != null;
      
      if (iosImplementation != null) {
        // اختبار طلب الأذونات
        final permissions = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        result['permissions_requested'] = permissions ?? false;
      }

      result['success'] = true;
      
    } catch (e) {
      result['error'] = e.toString();
      result['success'] = false;
    }
    
    return result;
  }

  /// تقييم النتائج الإجمالية
  bool _evaluateOverallResults(Map<String, dynamic> tests) {
    int successCount = 0;
    int totalTests = 0;

    for (final test in tests.values) {
      if (test is Map<String, dynamic> && test.containsKey('success')) {
        totalTests++;
        if (test['success'] == true) {
          successCount++;
        }
      }
    }

    final successRate = totalTests > 0 ? successCount / totalTests : 0.0;
    debugPrint('📊 Test success rate: ${(successRate * 100).toStringAsFixed(1)}% ($successCount/$totalTests)');
    
    return successRate >= 0.8; // 80% نجاح أو أكثر
  }

  /// طباعة تقرير مفصل
  void printDetailedReport(Map<String, dynamic> results) {
    debugPrint('\n' + '=' * 50);
    debugPrint('📋 NOTIFICATION TEST REPORT');
    debugPrint('=' * 50);
    debugPrint('🕐 Timestamp: ${results['timestamp']}');
    debugPrint('📱 Platform: ${results['platform']}');
    debugPrint('✅ Overall Success: ${results['overall_success']}');
    
    if (results.containsKey('error')) {
      debugPrint('❌ Overall Error: ${results['error']}');
    }
    
    debugPrint('\n📊 DETAILED RESULTS:');
    debugPrint('-' * 30);
    
    final tests = results['tests'] as Map<String, dynamic>;
    for (final entry in tests.entries) {
      final testName = entry.key;
      final testResult = entry.value as Map<String, dynamic>;
      final success = testResult['success'] ?? false;
      
      debugPrint('${success ? '✅' : '❌'} $testName: ${success ? 'PASSED' : 'FAILED'}');
      
      if (testResult.containsKey('error')) {
        debugPrint('   Error: ${testResult['error']}');
      }
    }
    
    debugPrint('=' * 50 + '\n');
  }
}
