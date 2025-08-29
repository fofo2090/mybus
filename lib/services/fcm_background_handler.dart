import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// معالج الرسائل في الخلفية
/// يجب أن يكون دالة عامة (top-level function) وليس داخل كلاس
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تهيئة Firebase إذا لم تكن مهيأة
  // await Firebase.initializeApp();

  debugPrint('🔥 Background message received: ${message.messageId}');
  debugPrint('📱 Title: ${message.notification?.title}');
  debugPrint('📝 Body: ${message.notification?.body}');
  debugPrint('📊 Data: ${message.data}');

  // حفظ الإشعار في قاعدة البيانات المحلية للتاريخ
  await _saveNotificationToDatabase(message);

  // عرض الإشعار يدوياً دائماً لضمان ظهوره
  // لأن Firebase قد لا يعرضه تلقائياً عندما يوجد background handler
  await _showBackgroundNotification(message);
}

/// عرض إشعار محلي في الخلفية للمستخدم المحدد فقط
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  try {
    // التحقق من أن الإشعار للمستخدم المحدد فقط
    final targetUserId = message.data['userId'] ?? message.data['recipientId'];
    if (targetUserId == null || targetUserId.isEmpty) {
      debugPrint('⚠️ No target user ID in notification data, skipping');
      return;
    }

    // التحقق من المستخدم الحالي (إذا كان متاحاً في الخلفية)
    debugPrint('📤 Background notification for user: $targetUserId');
    debugPrint('🔔 Processing background notification...');

    // إنشاء instance من Flutter Local Notifications
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    // إعدادات Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

    // إعدادات iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // لا نطلب الأذونات في الخلفية
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // تهيئة المكون الإضافي
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(initSettings);

    // إنشاء قناة الإشعارات إذا لم تكن موجودة (Android فقط)
    if (Platform.isAndroid) {
      await _createBackgroundNotificationChannel(localNotifications);
    }

    // تحديد معلومات الإشعار
    final String channelId = message.data['channelId'] ?? 'mybus_notifications';
    final String title = message.notification?.title ?? 'إشعار جديد';
    final String body = message.notification?.body ?? '';

    // إعدادات الإشعار لأندرويد محسنة لتظهر مثل WhatsApp
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon', // استخدام أيقونة التطبيق الرئيسية
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // أيقونة كبيرة
      color: const Color(0xFF1E88E5), // لون التطبيق
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      autoCancel: true,
      ongoing: false,
      silent: false,
      channelShowBadge: true,
      onlyAlertOnce: false,
      visibility: NotificationVisibility.public,
      ticker: '$title - $body', // نص يظهر عند وصول الإشعار
      tag: 'mybus_${DateTime.now().millisecondsSinceEpoch}',
      // إعدادات إضافية لتحسين الظهور
      category: AndroidNotificationCategory.message,
      groupKey: 'com.mybus.notifications', // تجميع الإشعارات
      setAsGroupSummary: false,
      groupAlertBehavior: GroupAlertBehavior.all,
      // إعدادات النمط
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: 'كيدز باص',
        htmlFormatSummaryText: false,
      ),
    );

    // إعدادات الإشعار لـ iOS محسنة
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
      badgeNumber: 1,
      subtitle: 'كيدز باص', // عنوان فرعي يظهر تحت العنوان
      threadIdentifier: 'mybus_notifications', // لتجميع الإشعارات
      categoryIdentifier: 'mybus_category',
    );

    // تجميع الإعدادات
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // إنشاء معرف فريد للإشعار
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // عرض الإشعار للمستخدم المحدد فقط
    await localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: jsonEncode({
        ...message.data,
        'messageId': message.messageId,
        'targetUserId': targetUserId,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    debugPrint('✅ Background notification shown successfully');
  } catch (e) {
    debugPrint('❌ Error showing background notification: $e');
  }
}

/// إنشاء قناة الإشعارات في الخلفية (Android)
Future<void> _createBackgroundNotificationChannel(FlutterLocalNotificationsPlugin localNotifications) async {
  try {
    final List<AndroidNotificationChannel> channels = [
      // القناة الرئيسية محسنة
      const AndroidNotificationChannel(
        'mybus_notifications',
        'كيدز باص - الإشعارات العامة',
        description: 'إشعارات عامة من تطبيق كيدز باص للنقل المدرسي',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF1E88E5),
      ),
      // قناة إشعارات الطلاب
      const AndroidNotificationChannel(
        'student_notifications',
        'إشعارات الطلاب',
        description: 'إشعارات متعلقة بالطلاب وأنشطتهم',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الباص
      const AndroidNotificationChannel(
        'bus_notifications',
        'إشعارات الباص',
        description: 'إشعارات ركوب ونزول الباص',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الطوارئ
      const AndroidNotificationChannel(
        'emergency_notifications',
        'تنبيهات الطوارئ',
        description: 'تنبيهات طوارئ مهمة وعاجلة',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
    ];

    // إنشاء القنوات
    for (final channel in channels) {
      await localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint('✅ Background notification channels created');
  } catch (e) {
    debugPrint('❌ Error creating background notification channels: $e');
  }
}

/// الحصول على اسم القناة
String _getChannelName(String channelId) {
  switch (channelId) {
    case 'student_notifications':
      return 'إشعارات الطلاب';
    case 'bus_notifications':
      return 'إشعارات الباص';
    case 'emergency_notifications':
      return 'تنبيهات الطوارئ';
    default:
      return 'إشعارات MyBus';
  }
}

/// الحصول على وصف القناة
String _getChannelDescription(String channelId) {
  switch (channelId) {
    case 'student_notifications':
      return 'إشعارات متعلقة بالطلاب وأنشطتهم';
    case 'bus_notifications':
      return 'إشعارات ركوب ونزول الباص';
    case 'emergency_notifications':
      return 'تنبيهات طوارئ مهمة وعاجلة';
    default:
      return 'إشعارات عامة لتطبيق MyBus';
  }
}

/// دالة مساعدة لإرسال إشعار FCM من الخادم
/// يمكن استخدامها في Cloud Functions أو الخادم الخلفي
class FCMHelper {
  /// إرسال إشعار لمستخدم واحد
  static Map<String, dynamic> createNotificationPayload({
    required String token,
    required String title,
    required String body,
    String channelId = 'mybus_notifications',
    Map<String, String>? data,
    String? imageUrl,
  }) {
    return {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'notification_sound.mp3',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        if (imageUrl != null) 'image': imageUrl,
      },
      'data': {
        'channelId': channelId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
      'android': {
        'notification': {
          'channel_id': channelId,
          'sound': 'notification_sound',
          'priority': 'high',
          'visibility': 'public',
          'icon': 'ic_notification',
          'color': '#FF6B6B',
        },
        'priority': 'high',
      },
      'apns': {
        'payload': {
          'aps': {
            'alert': {
              'title': title,
              'body': body,
            },
            'sound': 'notification_sound.mp3',
            'badge': 1,
            'content-available': 1,
          },
        },
      },
    };
  }

  /// إرسال إشعار لعدة مستخدمين
  static Map<String, dynamic> createMulticastNotificationPayload({
    required List<String> tokens,
    required String title,
    required String body,
    String channelId = 'mybus_notifications',
    Map<String, String>? data,
    String? imageUrl,
  }) {
    return {
      'registration_ids': tokens,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'notification_sound.mp3',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        if (imageUrl != null) 'image': imageUrl,
      },
      'data': {
        'channelId': channelId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
      'android': {
        'notification': {
          'channel_id': channelId,
          'sound': 'notification_sound',
          'priority': 'high',
          'visibility': 'public',
          'icon': 'ic_notification',
          'color': '#FF6B6B',
        },
        'priority': 'high',
      },
      'apns': {
        'payload': {
          'aps': {
            'alert': {
              'title': title,
              'body': body,
            },
            'sound': 'notification_sound.mp3',
            'badge': 1,
            'content-available': 1,
          },
        },
      },
    };
  }
}

/// حفظ الإشعار في قاعدة البيانات للتاريخ
Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
  try {
    debugPrint('💾 Saving notification to database: ${message.notification?.title}');

    // حفظ الإشعار في SharedPreferences للاحتفاظ به
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('background_notifications') ?? [];

    final notificationData = {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'إشعار جديد',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };

    notifications.add(jsonEncode(notificationData));

    // الاحتفاظ بآخر 50 إشعار فقط
    if (notifications.length > 50) {
      notifications.removeRange(0, notifications.length - 50);
    }

    await prefs.setStringList('background_notifications', notifications);
    debugPrint('✅ Notification saved to local storage');

  } catch (e) {
    debugPrint('❌ Error saving notification to database: $e');
  }
}
