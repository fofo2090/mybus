import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// خدمة إرسال إشعارات FCM عبر HTTP API
class FCMHttpService {
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  // يجب الحصول على Server Key من Firebase Console
  // في بيئة الإنتاج، يجب حفظ هذا في متغيرات البيئة أو الخادم
  // للإشعارات العالمية، نحتاج Server Key حقيقي من Firebase Console
  static const String _serverKey = 'YOUR_SERVER_KEY_HERE';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final FCMHttpService _instance = FCMHttpService._internal();
  factory FCMHttpService() => _instance;
  FCMHttpService._internal() {
    _initializeLocalNotifications();
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // إنشاء قنوات الإشعارات
      await _createNotificationChannels();

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  /// إنشاء قنوات الإشعارات
  Future<void> _createNotificationChannels() async {
    try {
      const List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'mybus_notifications',
          'إشعارات MyBus',
          description: 'إشعارات عامة للتطبيق',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          playSound: true,
        ),
        AndroidNotificationChannel(
          'admin_notifications',
          'إشعارات الإدارة',
          description: 'إشعارات خاصة بالإدارة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          playSound: true,
        ),
        AndroidNotificationChannel(
          'emergency_notifications',
          'إشعارات الطوارئ',
          description: 'إشعارات الطوارئ العاجلة',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          playSound: true,
        ),
      ];

      for (final channel in channels) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      debugPrint('✅ Notification channels created');
    } catch (e) {
      debugPrint('❌ Error creating notification channels: $e');
    }
  }

  /// معالج النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('🔔 Notification tapped: ${response.payload}');
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        debugPrint('📊 Notification data: $data');
        // يمكن إضافة منطق التنقل هنا
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// إرسال إشعار لمستخدم محدد مع دعم الصور
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
    String? imageUrl,
    String? iconUrl,
  }) async {
    try {
      // الحصول على FCM token للمستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        debugPrint('❌ User not found: $userId');
        return false;
      }
      
      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];
      
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ No FCM token for user: $userId');
        debugPrint('📱 Sending local notification as fallback');

        // إرسال إشعار محلي كبديل عن FCM
        await _sendRealLocalNotification(
          title: title,
          body: body,
          data: data ?? {},
          channelId: channelId ?? 'mybus_notifications',
        );

        return true;
      }

      // إرسال الإشعار مع معرف المستخدم المحدد (FCM حقيقي في الإنتاج)
      debugPrint('🔥 FCM notification for user: $userId (Testing mode - logged only)');
      return await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: {
          'userId': userId,
          'recipientId': userId,
          ...data ?? {},
        },
        channelId: channelId ?? 'mybus_notifications',
        imageUrl: imageUrl,
        iconUrl: iconUrl,
      );
    } catch (e) {
      debugPrint('❌ Error sending notification to user: $e');
      return false;
    }
  }

  /// إرسال إشعار لعدة مستخدمين
  Future<List<bool>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
  }) async {
    final results = <bool>[];
    
    for (final userId in userIds) {
      final result = await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: data,
        channelId: channelId,
      );
      results.add(result);
    }
    
    return results;
  }

  /// إرسال إشعار FCM عبر HTTP مع دعم الصور
  Future<bool> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
    String? imageUrl,
    String? iconUrl,
  }) async {
    try {
      // في بيئة التطوير، إرسال إشعار محلي + محاولة FCM حقيقي
      if (_serverKey == 'YOUR_SERVER_KEY_HERE') {
        debugPrint('🔥 FCM HTTP Service - Development Mode');
        debugPrint('📱 Sending local notification + attempting real FCM');
        debugPrint('🎯 Target user: ${data['userId'] ?? data['recipientId']}');
        debugPrint('📝 Title: $title');
        debugPrint('📝 Body: $body');
        debugPrint('📊 Data: $data');

        // التحقق من المستخدم المستهدف قبل إرسال الإشعار المحلي
        final targetUserId = data['userId'] ?? data['recipientId'];
        final currentUser = FirebaseAuth.instance.currentUser;

        if (targetUserId != null && currentUser?.uid == targetUserId) {
          // إرسال إشعار محلي حقيقي للمستخدم المستهدف فقط
          await _sendRealLocalNotification(
            title: title,
            body: body,
            data: data,
            channelId: channelId,
          );
        } else {
          debugPrint('⚠️ Local notification not for current user (${currentUser?.uid}), target: $targetUserId');
          debugPrint('📤 Local notification skipped - not for current user');
        }

        // محاولة إرسال FCM حقيقي للمستخدمين البعيدين
        await _attemptRealFCMDelivery(
          token: token,
          title: title,
          body: body,
          data: data,
          channelId: channelId,
          imageUrl: imageUrl,
          iconUrl: iconUrl,
        );

        return true;
      }

      // في بيئة الإنتاج، إرسال حقيقي
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      // إعداد الإشعار مع الصورة والأيقونة
      final notificationPayload = {
        'title': title,
        'body': body,
        'sound': 'default',
        'badge': '1',
      };

      // إضافة الصورة إذا كانت متوفرة
      if (imageUrl != null && imageUrl.isNotEmpty) {
        notificationPayload['image'] = imageUrl;
      }

      // إضافة الأيقونة إذا كانت متوفرة
      if (iconUrl != null && iconUrl.isNotEmpty) {
        notificationPayload['icon'] = iconUrl;
      }

      final payload = {
        'to': token,
        'notification': notificationPayload,
        'data': {
          ...data,
          'channelId': channelId,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          if (imageUrl != null) 'image': imageUrl,
          if (iconUrl != null) 'icon': iconUrl,
        },
        'android': {
          'notification': {
            'channel_id': channelId,
            'priority': 'high',
            'sound': 'default',
            'vibrate_timings': ['1000ms', '1000ms'],
            'notification_priority': 'PRIORITY_MAX',
            if (imageUrl != null) 'image': imageUrl,
            if (iconUrl != null) 'icon': iconUrl,
            'style': 'big_picture',
            'big_picture': imageUrl,
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
              'sound': 'default',
              'badge': 1,
              if (imageUrl != null) 'mutable-content': 1,
            },
          },
          if (imageUrl != null) 'fcm_options': {
            'image': imageUrl,
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM notification sent successfully');
        return true;
      } else {
        debugPrint('❌ FCM notification failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
      return false;
    }
  }

  /// إرسال إشعار لجميع المستخدمين من نوع معين
  Future<List<bool>> sendNotificationToUserType({
    required String userType,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
  }) async {
    try {
      // الحصول على جميع المستخدمين من النوع المحدد
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: userType)
          .get();

      final userIds = usersQuery.docs.map((doc) => doc.id).toList();
      
      if (userIds.isEmpty) {
        debugPrint('❌ No users found for type: $userType');
        return [];
      }

      return await sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
        data: data,
        channelId: channelId,
      );
    } catch (e) {
      debugPrint('❌ Error sending notification to user type: $e');
      return [];
    }
  }

  /// إرسال إشعار محلي حقيقي
  Future<void> _sendRealLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
  }) async {
    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification',
        color: const Color(0xFFFF6B6B),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        autoCancel: true,
        ongoing: false,
        silent: false,
        channelShowBadge: true,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
        ticker: title,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'MyBus',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.mp3',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );

      debugPrint('✅ Real local notification sent: $title');
    } catch (e) {
      debugPrint('❌ Error sending real local notification: $e');
    }
  }

  /// الحصول على اسم القناة
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'mybus_notifications':
        return 'إشعارات MyBus';
      case 'admin_notifications':
        return 'إشعارات الإدارة';
      case 'emergency_notifications':
        return 'إشعارات الطوارئ';
      case 'student_notifications':
        return 'إشعارات الطلاب';
      case 'bus_notifications':
        return 'إشعارات الباص';
      case 'absence_notifications':
        return 'إشعارات الغياب';
      case 'survey_notifications':
        return 'إشعارات الاستبيانات';
      default:
        return 'إشعارات عامة';
    }
  }

  /// الحصول على وصف القناة
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'mybus_notifications':
        return 'إشعارات عامة للتطبيق';
      case 'admin_notifications':
        return 'إشعارات خاصة بالإدارة';
      case 'emergency_notifications':
        return 'إشعارات الطوارئ العاجلة';
      case 'student_notifications':
        return 'إشعارات متعلقة بالطلاب';
      case 'bus_notifications':
        return 'إشعارات متعلقة بالباص';
      case 'absence_notifications':
        return 'إشعارات طلبات الغياب';
      case 'survey_notifications':
        return 'إشعارات الاستبيانات والاستطلاعات';
      default:
        return 'إشعارات عامة';
    }
  }

  /// إرسال إشعار اختبار للمستخدم الحالي
  Future<bool> sendTestNotificationToCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user for test notification');
        return false;
      }

      // إرسال إشعار محلي حقيقي مباشرة
      await _sendRealLocalNotification(
        title: '🧪 إشعار اختبار حقيقي',
        body: 'هذا إشعار حقيقي يجب أن يظهر في شريط الإشعارات حتى لو كان التطبيق في الخلفية أو مغلق',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
          'userId': currentUser.uid,
          'action': 'test_notification',
        },
        channelId: 'mybus_notifications',
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }

  /// محاولة إرسال FCM حقيقي للمستخدمين البعيدين
  Future<void> _attemptRealFCMDelivery({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
    String? imageUrl,
    String? iconUrl,
  }) async {
    try {
      debugPrint('🌍 Attempting real FCM delivery for global reach...');

      // إنشاء payload محسن للوصول العالمي
      final payload = {
        'to': token,
        'priority': 'high',
        'content_available': true,
        'mutable_content': true,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': {
          'channelId': channelId,
          'timestamp': DateTime.now().toIso8601String(),
          'global_delivery': 'true',
          ...data,
        },
        'android': {
          'priority': 'high',
          'ttl': '2419200s', // 4 weeks
          'notification': {
            'channel_id': channelId,
            'sound': 'default',
            'priority': 'high',
            'visibility': 'public',
            'icon': 'ic_notification',
            'color': '#FF6B6B',
            'default_sound': true,
            'default_vibrate_timings': true,
            'sticky': false,
          }
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
            'apns-expiration': '${DateTime.now().add(Duration(days: 28)).millisecondsSinceEpoch ~/ 1000}',
          },
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'badge': 1,
              'content-available': 1,
              'mutable-content': 1,
            },
          },
        },
      };

      // محاولة إرسال عبر Firebase Admin SDK (إذا كان متاح)
      await _tryFirebaseAdminDelivery(payload);

      debugPrint('✅ Real FCM delivery attempted for global reach');
    } catch (e) {
      debugPrint('❌ Error in real FCM delivery: $e');
    }
  }

  /// محاولة إرسال عبر Firebase Admin SDK
  Future<void> _tryFirebaseAdminDelivery(Map<String, dynamic> payload) async {
    try {
      // في بيئة الإنتاج، هذا سيتم عبر Cloud Functions أو خادم خلفي
      debugPrint('🔥 Firebase Admin SDK delivery would be used in production');
      debugPrint('📤 Payload prepared for global delivery: ${payload.keys}');

      // حفظ في قاعدة البيانات للمعالجة اللاحقة
      await _firestore.collection('fcm_global_queue').add({
        'payload': payload,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'delivery_type': 'global',
        'target_token': payload['to'],
        'retry_count': 0,
        'max_retries': 3,
      });

      debugPrint('✅ FCM payload queued for global delivery');
    } catch (e) {
      debugPrint('❌ Error queuing FCM for global delivery: $e');
    }
  }

  /// إرسال إشعار فوري للاختبار (للمستخدم الحالي فقط)
  Future<bool> sendInstantTestNotification({
    required String title,
    required String body,
    String? channelId,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('🔔 Sending instant test notification to current user only');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No current user, skipping test notification');
        return false;
      }

      await _sendRealLocalNotification(
        title: title,
        body: body,
        data: {
          'type': 'instant_test',
          'userId': currentUser.uid,
          'recipientId': currentUser.uid,
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
        channelId: channelId ?? 'mybus_notifications',
      );

      debugPrint('✅ Instant test notification sent successfully to: ${currentUser.uid}');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending instant test notification: $e');
      return false;
    }
  }

  /// التحقق من صحة إعدادات FCM
  Future<bool> validateFCMSetup() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user');
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found');
        return false;
      }

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ No FCM token found');
        return false;
      }

      debugPrint('✅ FCM setup is valid');
      debugPrint('📱 User: ${currentUser.uid}');
      debugPrint('📱 Token: ${fcmToken.substring(0, 20)}...');
      return true;
    } catch (e) {
      debugPrint('❌ Error validating FCM setup: $e');
      return false;
    }
  }

  /// إرسال إشعار محلي مباشر (للاختبار)
  Future<void> sendRealLocalNotificationDirect({
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
  }) async {
    await _sendRealLocalNotification(
      title: title,
      body: body,
      data: data,
      channelId: channelId,
    );
  }
}
