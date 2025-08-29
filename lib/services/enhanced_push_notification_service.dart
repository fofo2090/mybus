import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// خدمة الإشعارات المحسنة مع دعم الإشعارات خارج التطبيق
class EnhancedPushNotificationService {
  static final EnhancedPushNotificationService _instance = 
      EnhancedPushNotificationService._internal();
  factory EnhancedPushNotificationService() => _instance;
  EnhancedPushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _currentUserId;
  String? _fcmToken;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // طلب الأذونات
      await _requestPermissions();

      // الحصول على FCM Token
      await _getFCMToken();

      // تسجيل معالجات الرسائل
      _setupMessageHandlers();

      // تحديث معلومات المستخدم الحالي
      await _updateCurrentUser();

      _isInitialized = true;
      debugPrint('✅ Enhanced Push Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Enhanced Push Notification Service: $e');
    }
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

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
  }

  /// طلب الأذونات
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  /// الحصول على FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // حفظ التوكن محلياً
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // تحديث التوكن عند تغييره
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        
        // تحديث التوكن في قاعدة البيانات
        await _updateUserFCMToken(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// تحديث معلومات المستخدم الحالي
  Future<void> _updateCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _updateUserFCMToken(_fcmToken);
      await _subscribeToUserTopic();
    }
  }

  /// تحديث FCM Token في قاعدة البيانات
  Future<void> _updateUserFCMToken(String? token) async {
    if (_currentUserId == null || token == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': defaultTargetPlatform.name,
          'lastSeen': FieldValue.serverTimestamp(),
        }
      });
      debugPrint('✅ FCM token updated for user: $_currentUserId');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  /// الاشتراك في موضوع المستخدم
  Future<void> _subscribeToUserTopic() async {
    if (_currentUserId == null) return;

    try {
      await _messaging.subscribeToTopic('user_$_currentUserId');
      debugPrint('✅ Subscribed to user topic: user_$_currentUserId');
    } catch (e) {
      debugPrint('❌ Error subscribing to user topic: $e');
    }
  }

  /// إلغاء الاشتراك من موضوع المستخدم
  Future<void> _unsubscribeFromUserTopic() async {
    if (_currentUserId == null) return;

    try {
      await _messaging.unsubscribeFromTopic('user_$_currentUserId');
      debugPrint('✅ Unsubscribed from user topic: user_$_currentUserId');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from user topic: $e');
    }
  }

  /// تسجيل معالجات الرسائل
  void _setupMessageHandlers() {
    // معالج الرسائل في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالج النقر على الإشعار عندما يكون التطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // معالج الرسالة الأولية عند فتح التطبيق من إشعار
    _handleInitialMessage();
  }

  /// معالج الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Received foreground message: ${message.notification?.title}');
    
    // التحقق من المستخدم المستهدف
    if (!_isMessageForCurrentUser(message)) {
      debugPrint('⚠️ Message not for current user, skipping');
      return;
    }

    // عرض الإشعار المحلي
    await _showLocalNotification(message);

    // حفظ الإشعار في قاعدة البيانات
    await _saveNotificationToDatabase(message);
  }

  /// معالج النقر على الإشعار
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('🔔 Notification tapped: ${message.notification?.title}');
    
    // التحقق من المستخدم المستهدف
    if (!_isMessageForCurrentUser(message)) {
      debugPrint('⚠️ Tapped notification not for current user');
      return;
    }

    // معالجة النقر حسب نوع الإشعار
    await _handleNotificationAction(message);
  }

  /// معالج الرسالة الأولية
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App opened from notification: ${initialMessage.notification?.title}');
      await _handleNotificationTap(initialMessage);
    }
  }

  /// التحقق من أن الرسالة للمستخدم الحالي
  bool _isMessageForCurrentUser(RemoteMessage message) {
    final targetUserId = message.data['userId'] ?? 
                        message.data['recipientId'] ?? 
                        message.data['targetUserId'];
    
    // إذا لم يكن هناك مستخدم محدد، اعرض للجميع
    if (targetUserId == null) return true;
    
    // إذا كان هناك مستخدم محدد، تحقق من التطابق
    return _currentUserId == targetUserId;
  }

  /// عرض الإشعار المحلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'mybus_notifications',
        'كيدز باص',
        channelDescription: 'إشعارات تطبيق كيدز باص',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'إشعار جديد',
        message.notification?.body ?? '',
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      debugPrint('✅ Local notification shown');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// معالج النقر على الإشعار المحلي
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// معالجة بيانات الإشعار
  Future<void> _handleNotificationAction(RemoteMessage message) async {
    await _handleNotificationData(message.data);
  }

  /// معالجة بيانات الإشعار
  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    final type = data['type'] ?? 'general';
    final studentId = data['studentId'];
    final action = data['action'];

    debugPrint('🔔 Handling notification: type=$type, studentId=$studentId, action=$action');

    // يمكن إضافة منطق التنقل هنا حسب نوع الإشعار
    switch (type) {
      case 'student_boarded':
      case 'student_left':
        // التنقل لصفحة تتبع الطالب
        break;
      case 'trip_started':
      case 'trip_ended':
        // التنقل لصفحة الرحلات
        break;
      default:
        // التنقل للصفحة الرئيسية
        break;
    }
  }

  /// حفظ الإشعار في قاعدة البيانات
  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('user_notifications').add({
        'userId': _currentUserId,
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'receivedAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': message.data['type'] ?? 'general',
      });
      debugPrint('✅ Notification saved to database');
    } catch (e) {
      debugPrint('❌ Error saving notification to database: $e');
    }
  }

  /// إرسال إشعار لمستخدم محدد
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // الحصول على FCM token للمستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('⚠️ No FCM token found for user: $userId');
        return;
      }

      // إضافة الإشعار لقائمة الانتظار
      await _firestore.collection('fcm_queue').add({
        'recipientId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': {
          ...?data,
          'userId': userId,
          'recipientId': userId,
          'targetUserId': userId,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'sound': 'default',
          'priority': 'high',
          'channel_id': 'mybus_notifications',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': data?['type'] ?? 'general',
      });

      debugPrint('✅ Notification queued for user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification to user: $e');
    }
  }

  /// تحديث المستخدم الحالي
  Future<void> updateCurrentUser(String? userId) async {
    // إلغاء الاشتراك من الموضوع السابق
    if (_currentUserId != null) {
      await _unsubscribeFromUserTopic();
    }

    _currentUserId = userId;

    if (userId != null) {
      // تحديث FCM token والاشتراك في الموضوع الجديد
      await _updateUserFCMToken(_fcmToken);
      await _subscribeToUserTopic();
    }
  }

  /// تنظيف الخدمة عند تسجيل الخروج
  Future<void> cleanup() async {
    await _unsubscribeFromUserTopic();
    _currentUserId = null;
    
    // مسح FCM token من قاعدة البيانات
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    
    debugPrint('✅ Enhanced Push Notification Service cleaned up');
  }

  /// الحصول على المستخدم الحالي
  String? get currentUserId => _currentUserId;

  /// الحصول على FCM Token
  String? get fcmToken => _fcmToken;
}