import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// معالج محسن للرسائل في الخلفية مع دعم المستخدمين المحددين
class EnhancedBackgroundHandler {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  /// معالج الرسائل في الخلفية
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message received: ${message.notification?.title}');
    
    try {
      // تهيئة الإشعارات المحلية إذا لم تكن مهيأة
      await _initializeLocalNotifications();

      // التحقق من المستخدم المستهدف
      final targetUserId = message.data['userId'] ?? 
                          message.data['recipientId'] ?? 
                          message.data['targetUserId'];

      // الحصول على المستخدم الحالي المحفوظ
      final currentUserId = await _getCurrentUserId();
      
      debugPrint('🎯 Target user: $targetUserId');
      debugPrint('👤 Current user: $currentUserId');

      // التحقق من أن الرسالة للمستخدم الحالي
      if (targetUserId != null && currentUserId != null && targetUserId != currentUserId) {
        debugPrint('⚠️ Message not for current user, skipping notification');
        // حفظ الرسالة في قاعدة البيانات فقط
        await _saveMessageToDatabase(message, false);
        return;
      }

      // عرض الإشعار المحلي
      await _showBackgroundNotification(message);

      // حفظ الرسالة في قاعدة البيانات
      await _saveMessageToDatabase(message, true);

      debugPrint('✅ Background message processed successfully');
    } catch (e) {
      debugPrint('❌ Error processing background message: $e');
    }
  }

  /// تهيئة الإشعارات المحلية
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // إنشاء قناة الإشعارات لـ Android
      if (!kIsWeb) {
        const androidChannel = AndroidNotificationChannel(
          'mybus_notifications',
          'كيدز باص',
          description: 'إشعارات تطبيق كيدز باص',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          playSound: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      }
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  /// الحصول على معرف المستخدم الحالي من التخزين المحلي
  static Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userId = prefs.getString('user_id');
      
      if (isLoggedIn && userId != null) {
        return userId;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current user ID: $e');
      return null;
    }
  }

  /// عرض الإشعار في الخلفية
  static Future<void> _showBackgroundNotification(RemoteMessage message) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'mybus_notifications',
        'كيدز باص',
        channelDescription: 'إشعارات تطبيق كيدز باص',
        importance: Importance.high,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(''),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        ticker: message.notification?.title,
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
        badgeNumber: 1,
        categoryIdentifier: 'mybus_category',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'إشعار جديد',
        message.notification?.body ?? '',
        notificationDetails,
        payload: jsonEncode({
          ...message.data,
          'messageId': message.messageId,
          'sentTime': message.sentTime?.millisecondsSinceEpoch,
        }),
      );

      debugPrint('✅ Background notification shown');
    } catch (e) {
      debugPrint('❌ Error showing background notification: $e');
    }
  }

  /// حفظ الرسالة في قاعدة البيانات
  static Future<void> _saveMessageToDatabase(RemoteMessage message, bool wasDisplayed) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = await _getCurrentUserId();

      // حفظ الإشعار في مجموعة الإشعارات العامة
      await firestore.collection('notifications').add({
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'إشعار جديد',
        'body': message.notification?.body ?? '',
        'recipientId': message.data['recipientId'] ?? message.data['userId'] ?? currentUserId,
        'type': message.data['type'] ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          ...message.data,
          'messageId': message.messageId,
          'sentTime': message.sentTime?.millisecondsSinceEpoch,
          'receivedInBackground': true,
          'wasDisplayed': wasDisplayed,
          'receivedAt': DateTime.now().toIso8601String(),
        },
        'notification_settings': {
          'sound': true,
          'vibration': true,
          'priority': 'high',
          'show_in_foreground': true,
          'background_processed': true,
        }
      });

      // حفظ الإشعار في مجموعة إشعارات المستخدم إذا كان محدداً
      if (currentUserId != null) {
        await firestore.collection('user_notifications').add({
          'userId': currentUserId,
          'messageId': message.messageId,
          'title': message.notification?.title,
          'body': message.notification?.body,
          'data': message.data,
          'receivedAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': message.data['type'] ?? 'general',
          'wasDisplayed': wasDisplayed,
          'processedInBackground': true,
        });
      }

      // إضافة log للتتبع
      await firestore.collection('notification_logs').add({
        'message_id': message.messageId,
        'title': message.notification?.title,
        'target_user': message.data['recipientId'] ?? message.data['userId'],
        'current_user': currentUserId,
        'received_at': FieldValue.serverTimestamp(),
        'type': 'background',
        'was_displayed': wasDisplayed,
        'platform': defaultTargetPlatform.name,
        'app_state': 'background',
      });

      debugPrint('✅ Background message saved to database');
    } catch (e) {
      debugPrint('❌ Error saving background message: $e');
    }
  }

  /// معالج النقر على الإشعار في الخلفية
  static Future<void> handleNotificationTap(String? payload) async {
    if (payload == null) return;

    try {
      final data = jsonDecode(payload);
      debugPrint('🔔 Background notification tapped: $data');

      // يمكن إضافة منطق التنقل هنا
      await _handleNotificationAction(data);
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// معالجة إجراء الإشعار
  static Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    final type = data['type'] ?? 'general';
    final studentId = data['studentId'];
    final action = data['action'];

    debugPrint('🔔 Processing notification action: type=$type, studentId=$studentId, action=$action');

    // حفظ معلومات النقر للمعالجة عند فتح التطبيق
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification_action', jsonEncode({
        'type': type,
        'studentId': studentId,
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      debugPrint('✅ Notification action saved for app launch');
    } catch (e) {
      debugPrint('❌ Error saving notification action: $e');
    }
  }

  /// الحصول على الإجراء المعلق
  static Future<Map<String, dynamic>?> getPendingNotificationAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionJson = prefs.getString('pending_notification_action');
      
      if (actionJson != null) {
        await prefs.remove('pending_notification_action');
        return jsonDecode(actionJson);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting pending notification action: $e');
      return null;
    }
  }

  /// تنظيف الإشعارات القديمة
  static Future<void> cleanupOldNotifications() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // حذف الإشعارات الأقدم من 30 يوم
      final oldNotifications = await firestore
          .collection('notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      debugPrint('❌ Error cleaning up old notifications: $e');
    }
  }
}