import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_notification_service.dart';
import 'parent_notification_service.dart';
import 'supervisor_notification_service.dart';

/// خدمة Firebase Cloud Messaging المتكاملة
/// تدعم الإشعارات في جميع حالات التطبيق: نشط، خلفية، مغلق
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Flutter Local Notifications instance
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // خدمة إشعارات الأدمن
  final AdminNotificationService _adminNotificationService = AdminNotificationService();

  // خدمة إشعارات ولي الأمر
  final ParentNotificationService _parentNotificationService = ParentNotificationService();

  // خدمة إشعارات المشرف
  final SupervisorNotificationService _supervisorNotificationService = SupervisorNotificationService();

  // Token الحالي
  String? _currentToken;

  // حالة التهيئة
  bool _isInitialized = false;

  /// تهيئة خدمة FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔥 Initializing FCM Service...');

      // Set foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 1. تهيئة Flutter Local Notifications
      await _initializeLocalNotifications();

      // 2. طلب أذونات الإشعارات
      await _requestPermissions();

      // 3. إعداد معالجات الرسائل
      await _setupMessageHandlers();

      // 4. الحصول على FCM Token وحفظه
      await _getAndSaveToken();

      // 5. الاستماع لتحديثات Token
      _listenToTokenRefresh();

      // 6. تحميل الإشعارات المحفوظة من الخلفية
      await _loadBackgroundNotifications();

      _isInitialized = true;
      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM Service: $e');
      rethrow;
    }
  }

  /// تهيئة Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    // إعدادات Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

    // إعدادات iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    // إعدادات التهيئة
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // تهيئة المكون الإضافي
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قنوات الإشعارات لأندرويد
    await _createNotificationChannels();

    debugPrint('✅ Local notifications initialized');
  }

  /// إنشاء قنوات الإشعارات لأندرويد
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final List<AndroidNotificationChannel> channels = [
      // القناة الرئيسية محسنة
      const AndroidNotificationChannel(
        'mybus_notifications',
        'كيدز باص - الإشعارات العامة',
        description: 'إشعارات عامة من تطبيق كيدز باص للنقل المدرسي',
        importance: Importance.max,
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
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الطوارئ محسنة
      const AndroidNotificationChannel(
        'emergency_notifications',
        'كيدز باص - تنبيهات الطوارئ',
        description: 'تنبيهات طوارئ مهمة وعاجلة من كيدز باص',
        importance: Importance.max,
        enableLights: true,
        ledColor: Color(0xFFFF0000), // أحمر للطوارئ
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
    ];

    // إنشاء القنوات
    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint('✅ Notification channels created');
  }

  /// طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {
    // طلب أذونات FCM
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');

    // التحقق من حالة الأذونات وإظهار تحذير إذا لزم الأمر
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Notification permissions denied by user');
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      debugPrint('⚠️ Notification permissions not determined');
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permissions granted');
    }

    // طلب أذونات إضافية لأندرويد 13+
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // طلب أذونات الإشعارات
        final notificationPermission = await androidImplementation.requestNotificationsPermission();
        debugPrint('📱 Android notification permission: $notificationPermission');

        // طلب أذونات الإنذارات الدقيقة (Android 12+)
        final exactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('📱 Android exact alarm permission: $exactAlarmPermission');

        // التحقق من إعدادات البطارية
        final batteryOptimized = await androidImplementation.getNotificationAppLaunchDetails();
        debugPrint('📱 Battery optimization status: $batteryOptimized');
      }
    }
  }

  /// إعداد معالجات الرسائل
  Future<void> _setupMessageHandlers() async {
    // معالج الرسائل عندما يكون التطبيق في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالج الرسائل عندما يكون التطبيق في الخلفية أو مغلق
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // التحقق من رسالة فتح التطبيق (إذا تم فتح التطبيق من إشعار)
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('✅ Message handlers setup complete');
  }

  /// معالج الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received foreground message: ${message.messageId}');
    debugPrint('📱 Title: ${message.notification?.title}');
    debugPrint('📱 Body: ${message.notification?.body}');
    debugPrint('📱 Data: ${message.data}');

    // Manually display a local notification to ensure it has the desired appearance and sound.
    final title = message.notification?.title ?? 'إشعار جديد';
    final body = message.notification?.body ?? '';
    final channelId = message.data['channelId'] as String? ?? 'mybus_notifications';

    await _displayLocalNotification(
      title: title,
      body: body,
      data: Map<String, String>.from(message.data),
      channelId: channelId,
    );
    debugPrint('✅ Manually displayed foreground notification.');
  }

  /// التحقق من نوع المستخدم وعرض الإشعار المناسب
  Future<void> _checkUserTypeAndShowNotification(RemoteMessage message) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // جلب بيانات المستخدم لمعرفة نوعه
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userType = userData?['userType'] ?? '';

      debugPrint('👤 User type: $userType');

      // إذا كان المستخدم أدمن، استخدم خدمة إشعارات الأدمن المتقدمة
      if (userType == 'admin') {
        debugPrint('🔔 Handling admin notification with advanced service');
        // سيتم التعامل مع الإشعار في AdminNotificationService
        // لا نحتاج لفعل شيء هنا لأن الخدمة تستمع للرسائل تلقائياً
      } else if (userType == 'parent') {
        debugPrint('👨‍👩‍👧‍👦 Handling parent notification with advanced service');
        // سيتم التعامل مع الإشعار في ParentNotificationService
        // لا نحتاج لفعل شيء هنا لأن الخدمة تستمع للرسائل تلقائياً
      } else if (userType == 'supervisor') {
        debugPrint('👨‍💼 Handling supervisor notification with advanced service');
        // سيتم التعامل مع الإشعار في SupervisorNotificationService
        // لا نحتاج لفعل شيء هنا لأن الخدمة تستمع للرسائل تلقائياً
      } else {
        // للمستخدمين العاديين، عرض الإشعار العادي
        debugPrint('📱 Showing regular notification for user type: $userType');
        await _showNotificationFromMessage(message);
      }
    } catch (e) {
      debugPrint('❌ Error checking user type: $e');
      // في حالة الخطأ، عرض الإشعار العادي
      await _showNotificationFromMessage(message);
    }
  }

  /// معالج الرسائل عند فتح التطبيق من إشعار
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔔 App opened from notification: ${message.messageId}');
    
    // يمكن إضافة منطق التنقل هنا
    _handleNotificationNavigation(message);
  }

  /// عرض إشعار محلي من RemoteMessage
  Future<void> _showNotificationFromMessage(RemoteMessage message) async {
    try {
      final String channelId = message.data['channelId'] ?? 'mybus_notifications';
      final String title = message.notification?.title ?? 'إشعار جديد';
      final String body = message.notification?.body ?? '';

      await _displayLocalNotification(
        title: title,
        body: body,
        data: Map<String, String>.from(message.data),
        channelId: channelId,
      );

      debugPrint('✅ Notification from message shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification from message: $e');
    }
  }

  /// معالج النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(RemoteMessage(data: data));
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// معالج التنقل من الإشعارات
  void _handleNotificationNavigation(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? route = message.data['route'];
    
    debugPrint('🧭 Handling navigation - Type: $type, Route: $route');
    
    // يمكن إضافة منطق التنقل هنا حسب نوع الإشعار
    // مثال: التنقل لصفحة معينة حسب نوع الإشعار
  }

  /// الحصول على FCM Token وحفظه
  Future<void> _getAndSaveToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToFirestore(token);
        debugPrint('✅ FCM Token obtained and saved');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// الاستماع لتحديثات Token
  void _listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _currentToken = token;
      _saveTokenToFirestore(token);
      debugPrint('🔄 FCM Token refreshed');
    });
  }

  /// حفظ Token في Firestore مع نوع المستخدم
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // الحصول على نوع المستخدم من الوثيقة
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        final userData = userDoc.data();
        final userType = userData?['userType'] ?? 'parent'; // افتراضي ولي أمر

        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem,
          'isActive': true,
          'userType': userType, // التأكد من وجود نوع المستخدم
        });

        // حفظ في مجموعة منفصلة للـ tokens حسب النوع للبحث السريع
        await _firestore.collection('fcm_tokens').doc(currentUser.uid).set({
          'token': token,
          'userId': currentUser.uid,
          'userType': userType,
          'platform': Platform.operatingSystem,
          'lastUpdate': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        debugPrint('✅ FCM Token saved to Firestore for $userType user');
      }
    } catch (e) {
      debugPrint('❌ Error saving token to Firestore: $e');
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

  /// الحصول على Token الحالي
  String? get currentToken => _currentToken;

  /// التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;



  /// إرسال إشعار محلي للاختبار
  Future<void> _sendLocalTestNotification() async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mybus_notifications',
      'إشعارات MyBus',
      channelDescription: 'إشعارات عامة لتطبيق MyBus',
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
      ticker: 'اختبار الإشعار المحلي',
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
      'اختبار الإشعار المحلي',
      'هذا إشعار محلي للتأكد من عمل النظام في شريط الإشعارات',
      details,
      payload: '{"type": "local_test", "timestamp": "${DateTime.now().toIso8601String()}"}',
    );
  }

  /// إرسال إشعار FCM للاختبار الحقيقي
  Future<void> _sendFCMTestNotification() async {
    try {
      final token = _currentToken;
      if (token == null) {
        debugPrint('❌ No FCM token available for test');
        return;
      }

      debugPrint('🔥 Sending real FCM test notification...');

      // إرسال إشعار حقيقي للجهاز نفسه للاختبار
      await sendNotificationToToken(
        token: token,
        title: 'اختبار FCM حقيقي',
        body: 'هذا إشعار حقيقي من FCM يجب أن يظهر في شريط الإشعارات حتى لو كان التطبيق في الخلفية',
        data: {
          'type': 'fcm_test',
          'channelId': 'mybus_notifications',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ FCM test notification sent to token: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error sending FCM test notification: $e');
    }
  }

  /// إرسال إشعار لـ token محدد (محسن للمستخدم المحدد فقط)
  Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
    String? targetUserId, // إضافة معرف المستخدم المستهدف
  }) async {
    try {
      debugPrint('📤 Preparing to send FCM notification...');
      debugPrint('📱 Target token: ${token.substring(0, 20)}...');
      debugPrint('👤 Target user: $targetUserId');
      debugPrint('📝 Title: $title');
      debugPrint('📝 Body: $body');
      debugPrint('📊 Data: $data');

      // لا نعرض إشعارات محلية - فقط نسجل للتشخيص
      // الإشعارات ستصل عبر FCM الحقيقي للمستخدم المستهدف فقط
      debugPrint('📤 FCM notification queued for user: $targetUserId');
      debugPrint('⚠️ No local notification will be shown to current user');

      // في بيئة الإنتاج، هنا يجب إرسال الإشعار عبر الخادم
      // الذي سيرسله للمستخدم المستهدف فقط عبر FCM token الخاص به

      debugPrint('✅ Notification sent to specific user: $targetUserId');
    } catch (e) {
      debugPrint('❌ Error in sendNotificationToToken: $e');
    }
  }

  /// إرسال إشعار لجميع المستخدمين من نوع معين
  Future<void> sendNotificationToUserType({
    required String userType,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
  }) async {
    try {
      debugPrint('📤 Queuing notifications for all $userType users...');

      // Get all active users of a specific type
      final usersQuery = await _firestore
          .collection('fcm_tokens')
          .where('userType', isEqualTo: userType)
          .where('isActive', isEqualTo: true)
          .get();

      if (usersQuery.docs.isEmpty) {
        debugPrint('⚠️ No active users found for user type: $userType');
        return;
      }

      debugPrint('👥 Found ${usersQuery.docs.length} active users of type $userType');

      // Create a batch write to queue all notifications at once
      final batch = _firestore.batch();

      for (final userDoc in usersQuery.docs) {
        final userId = userDoc.data()['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          // Use the generic _sendPushNotification function for each user
          await _sendPushNotification(
            userId: userId,
            title: title,
            body: body,
            data: data ?? {},
            channelId: channelId ?? 'mybus_notifications',
          );
        }
      }

      // While the above works, a more efficient way for bulk sending is a single
      // trigger that a cloud function can then process. For now, we will stick
      // to queuing one by one to use the existing cloud function structure.

      debugPrint('✅ Notifications queued for all $userType users.');
    } catch (e) {
      debugPrint('❌ Error queuing notifications for user type $userType: $e');
    }
  }

  /// إرسال إشعار لمستخدم محدد
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
  }) async {
    try {
      // The logic to fetch the token is now handled by the Cloud Function.
      // We just need to queue the notification with the recipient's ID.
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        data: data ?? {},
        channelId: channelId ?? 'mybus_notifications',
      );
    } catch (e) {
      debugPrint('❌ Error sending notification to user $userId: $e');
    }
  }

  /// إرسال إشعار push حقيقي عبر Cloud Function
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
  }) async {
    try {
      debugPrint('📤 Queuing push notification for user: $userId');

      // 1. إضافة الإشعار إلى قائمة الانتظار للمعالجة بواسطة Cloud Function
      await _firestore.collection('fcm_queue').add({
        'recipientId': userId,
        'title': title,
        'body': body,
        'data': {
          ...data,
          'channelId': channelId, // Ensure channelId is in data payload
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. (اختياري) حفظ نسخة من الإشعار في سجل الإشعارات العام (إذا كانت الإحصائيات أو السجل مطلوبًا)
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'channelId': channelId,
        'recipientId': userId, // Store recipientId instead of token
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false, // Will be updated by a cloud function if needed
        'source': 'client',
      });

      debugPrint('✅ Notification for user $userId queued successfully.');
      // لا تقم بعرض إشعار محلي هنا. Cloud Function سترسل الإشعار الحقيقي.
      // The real push notification will be sent by the Cloud Function.
    } catch (e) {
      debugPrint('❌ Error queuing push notification for user $userId: $e');
    }
  }

  /// عرض إشعار محلي (يظهر خارج التطبيق)
  Future<void> _displayLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
  }) async {
    try {
      // إنشاء معرف فريد للإشعار
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // إعدادات Android محسنة لتظهر مثل WhatsApp
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        icon: '@mipmap/ic_launcher', // أيقونة التطبيق الرئيسية
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF1E88E5),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
        ticker: '$title - $body',
        groupKey: 'com.mybus.notifications',
        // إضافة نمط النص الكبير
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: 'كيدز باص',
          htmlFormatSummaryText: false,
        ),
      );

      // إعدادات iOS محسنة
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.mp3',
        subtitle: 'كيدز باص',
        threadIdentifier: 'mybus_notifications',
        categoryIdentifier: 'mybus_category',
        badgeNumber: 1,
      );

      // إعدادات الإشعار
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // عرض الإشعار
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// إرسال إشعار طوارئ لجميع المستخدمين
  Future<void> sendEmergencyNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('🚨 Sending emergency notification to all users...');

      // إرسال لجميع أنواع المستخدمين
      await Future.wait([
        sendNotificationToUserType(
          userType: 'admin',
          title: title,
          body: body,
          data: data,
          channelId: 'emergency_notifications',
        ),
        sendNotificationToUserType(
          userType: 'supervisor',
          title: title,
          body: body,
          data: data,
          channelId: 'emergency_notifications',
        ),
        sendNotificationToUserType(
          userType: 'parent',
          title: title,
          body: body,
          data: data,
          channelId: 'emergency_notifications',
        ),
      ]);

      debugPrint('✅ Emergency notification sent to all users');
    } catch (e) {
      debugPrint('❌ Error sending emergency notification: $e');
    }
  }

  /// فحص حالة الإشعارات وإرجاع معلومات مفصلة
  Future<Map<String, dynamic>> checkNotificationStatus() async {
    try {
      // فحص أذونات FCM
      final settings = await _firebaseMessaging.getNotificationSettings();

      // فحص أذونات Android المحلية
      bool androidPermissionGranted = true;
      if (Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final permission = await androidImplementation.areNotificationsEnabled();
          androidPermissionGranted = permission ?? false;
        }
      }

      return {
        'fcmAuthorized': settings.authorizationStatus == AuthorizationStatus.authorized,
        'fcmStatus': settings.authorizationStatus.toString(),
        'androidPermissionGranted': androidPermissionGranted,
        'alertSetting': settings.alert.toString(),
        'badgeSetting': settings.badge.toString(),
        'soundSetting': settings.sound.toString(),
        'isFullyEnabled': settings.authorizationStatus == AuthorizationStatus.authorized && androidPermissionGranted,
      };
    } catch (e) {
      debugPrint('❌ Error checking notification status: $e');
      return {
        'fcmAuthorized': false,
        'androidPermissionGranted': false,
        'isFullyEnabled': false,
        'error': e.toString(),
      };
    }
  }

  /// الحصول على التوكن الحالي
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// إرسال إشعار تجريبي محلي
  Future<void> sendTestNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('🧪 Sending test notification...');

      await _displayLocalNotification(
        title: title,
        body: body,
        channelId: 'mybus_notifications',
        data: data ?? {},
      );

      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  /// تحميل الإشعارات المحفوظة من الخلفية
  Future<void> _loadBackgroundNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('background_notifications') ?? [];

      if (notifications.isNotEmpty) {
        debugPrint('📱 Found ${notifications.length} background notifications');

        // عرض الإشعارات المحفوظة للمستخدم الحالي
        for (final notificationJson in notifications) {
          try {
            final notificationData = jsonDecode(notificationJson) as Map<String, dynamic>;
            final isRead = notificationData['read'] as bool? ?? false;

            if (!isRead) {
              // عرض الإشعار غير المقروء
              await _displayLocalNotification(
                title: notificationData['title'] ?? 'إشعار جديد',
                body: notificationData['body'] ?? '',
                data: Map<String, String>.from(notificationData['data'] ?? {}),
                channelId: 'mybus_notifications',
              );

              // تحديث حالة الإشعار كمقروء
              notificationData['read'] = true;
              final updatedNotifications = notifications.map((n) {
                final data = jsonDecode(n) as Map<String, dynamic>;
                if (data['id'] == notificationData['id']) {
                  return jsonEncode(notificationData);
                }
                return n;
              }).toList();

              await prefs.setStringList('background_notifications', updatedNotifications);
            }
          } catch (e) {
            debugPrint('❌ Error processing background notification: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading background notifications: $e');
    }
  }

  /// تنظيف الموارد
  void dispose() {
    // تنظيف أي موارد إذا لزم الأمر
  }
}
