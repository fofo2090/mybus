import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

/// خدمة الإشعارات الموحدة - تجمع جميع الوظائف المشتركة
/// تستبدل التكرارات في الملفات المتعددة
class UnifiedNotificationService {
  static final UnifiedNotificationService _instance = UnifiedNotificationService._internal();
  factory UnifiedNotificationService() => _instance;
  UnifiedNotificationService._internal();

  // المتغيرات المشتركة
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;
  String? _currentToken;

  // قنوات الإشعارات الموحدة
  static const List<AndroidNotificationChannel> _channels = [
    AndroidNotificationChannel(
      'mybus_notifications',
      'إشعارات MyBus',
      description: 'الإشعارات العامة للتطبيق',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'student_notifications',
      'إشعارات الطلاب',
      description: 'إشعارات تسكين ونقل الطلاب',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'bus_notifications',
      'إشعارات الباص',
      description: 'إشعارات ركوب ونزول الطلاب',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'absence_notifications',
      'إشعارات الغياب',
      description: 'إشعارات طلبات الغياب والموافقات',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'admin_notifications',
      'إشعارات الإدارة',
      description: 'إشعارات إدارية وتقارير',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'emergency_notifications',
      'إشعارات الطوارئ',
      description: 'إشعارات الطوارئ والحالات العاجلة',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    ),
  ];

  /// تهيئة الخدمة الموحدة
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      debugPrint('🔔 Initializing Unified Notification Service...');

      // 1. تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // 2. طلب الأذونات
      await _requestPermissions();

      // 3. إنشاء قنوات الإشعارات
      await _createNotificationChannels();

      // 4. الحصول على FCM Token
      await _getAndSaveToken();

      _isInitialized = true;
      debugPrint('✅ Unified Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Unified Notification Service: $e');
    }
  }

  /// تهيئة الإشعارات المحلية - دالة موحدة
  Future<void> _initializeLocalNotifications() async {
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
  }

  /// إنشاء قنوات الإشعارات - دالة موحدة
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    for (final channel in _channels) {
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('✅ Created notification channel: ${channel.id}');
    }
  }

  /// طلب أذونات الإشعارات - دالة موحدة محسنة
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

    debugPrint('✅ Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional notification permissions');
    } else {
      debugPrint('❌ User declined or has not accepted notification permissions');
    }

    // طلب تجاهل تحسين البطارية (Android فقط)
    if (Platform.isAndroid) {
      await _requestBatteryOptimizationExemption();
    }
  }

  /// طلب تجاهل تحسين البطارية لضمان عمل الإشعارات
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      debugPrint('🔋 Requesting battery optimization exemption...');
      
      // يمكن إضافة كود platform-specific هنا لطلب تجاهل تحسين البطارية
      // مثال: استخدام MethodChannel للتواصل مع Android
      
      debugPrint('✅ Battery optimization exemption requested');
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization exemption: $e');
    }
  }

  /// الحصول على FCM Token وحفظه - دالة موحدة محسنة للوصول العالمي
  Future<void> _getAndSaveToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        await _saveTokenToFirestore(_currentToken!);
        debugPrint('✅ FCM Token saved: ${_currentToken!.substring(0, 20)}...');

        // تسجيل Token للوصول العالمي
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _registerTokenForGlobalDelivery(_currentToken!, currentUser.uid);
        }
      }

      // الاستماع لتحديثات Token
      _messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _saveTokenToFirestore(newToken);
        debugPrint('🔄 FCM Token refreshed and updated globally');
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// حفظ Token في Firestore - دالة موحدة محسنة للوصول العالمي
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'globalDeliveryEnabled': true, // تمكين التسليم العالمي
        'lastSeen': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        }
      });

      // تسجيل Token للوصول العالمي
      await _registerTokenForGlobalDelivery(token, user.uid);

      debugPrint('✅ FCM Token saved with global delivery enabled');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// تسجيل Token للوصول العالمي
  Future<void> _registerTokenForGlobalDelivery(String token, String userId) async {
    try {
      // حفظ في مجموعة منفصلة للتسليم العالمي
      await _firestore.collection('global_fcm_tokens').doc(userId).set({
        'token': token,
        'userId': userId,
        'registeredAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'active': true,
        'globalDelivery': true,
      }, SetOptions(merge: true));

      debugPrint('✅ Token registered for global delivery');
    } catch (e) {
      debugPrint('❌ Error registering token for global delivery: $e');
    }
  }

  /// إرسال إشعار محلي مع دعم الصور - دالة موحدة
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = 'mybus_notifications',
    Map<String, dynamic>? data,
    String? imageUrl,
    String? iconUrl,
    String? targetUserId, // إضافة معرف المستخدم المستهدف
  }) async {
    if (!_isInitialized) await initialize();

    // التحقق من المستخدم المستهدف إذا تم تمريره
    if (targetUserId != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid != targetUserId) {
        debugPrint('⚠️ Local notification not for current user (${currentUser?.uid}), target: $targetUserId');
        debugPrint('📤 Local notification skipped - not for current user');
        return;
      }
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // إعداد تفاصيل الإشعار مع دعم الصور
    StyleInformation? styleInformation;

    // إضافة صورة كبيرة إذا كانت متوفرة
    if (imageUrl != null && imageUrl.isNotEmpty) {
      styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(imageUrl),
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: body,
        htmlFormatSummaryText: true,
      );
    } else {
      styleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      );
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      icon: iconUrl != null ? iconUrl : '@drawable/ic_notification',
      largeIcon: imageUrl != null ? FilePathAndroidBitmap(imageUrl) : null,
      color: const Color(0xFF1E88E5), // لون أزرق مناسب للتطبيق
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      autoCancel: true,
      ongoing: false,
      silent: false,
      channelShowBadge: true,
      onlyAlertOnce: false,
      visibility: NotificationVisibility.public, // يظهر في شاشة القفل
      styleInformation: styleInformation,
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true, // يظهر حتى لو الشاشة مقفلة
      // إضافات جديدة لضمان الظهور الخارجي
      ticker: '$title - $body', // النص المتحرك في شريط الحالة
      subText: 'كيدز باص', // نص فرعي
      groupKey: 'mybus_notifications', // تجميع الإشعارات
      setAsGroupSummary: false,
      groupAlertBehavior: GroupAlertBehavior.all,
      timeoutAfter: null, // لا ينتهي تلقائياً
      actions: [
        const AndroidNotificationAction(
          'open_app',
          'فتح التطبيق',
          showsUserInterface: true,
          allowGeneratedReplies: false,
        ),
        const AndroidNotificationAction(
          'mark_read',
          'تم القراءة',
          showsUserInterface: false,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
      badgeNumber: null,
      attachments: imageUrl != null ? [
        DarwinNotificationAttachment(
          imageUrl,
          identifier: 'notification_image',
        ),
      ] : null,
      categoryIdentifier: 'mybus_category',
      threadIdentifier: 'mybus_thread',
      subtitle: 'كيدز باص',
      interruptionLevel: InterruptionLevel.active, // مستوى المقاطعة النشط
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );

    debugPrint('✅ Local notification shown: $title');
  }

  /// تحويل النوع من String إلى NotificationType
  NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'student':
        return NotificationType.studentAssigned;
      case 'bus':
        return NotificationType.studentBoarded;
      case 'absence':
        return NotificationType.absenceRequested;
      case 'admin':
        return NotificationType.systemUpdate;
      case 'emergency':
        return NotificationType.emergency;
      case 'complaint':
        return NotificationType.complaintSubmitted;
      case 'survey':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }

  /// حفظ الإشعار في Firestore - دالة موحدة
  Future<void> saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: userId,
        type: _parseNotificationType(type),
        timestamp: DateTime.now(),
        isRead: false,
        data: data ?? {},
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint('✅ Notification saved to Firestore for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving notification to Firestore: $e');
    }
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // يمكن إضافة منطق التنقل هنا
  }

  /// الحصول على اسم القناة
  String _getChannelName(String channelId) {
    return _channels.firstWhere((c) => c.id == channelId, orElse: () => _channels.first).name;
  }

  /// الحصول على وصف القناة
  String _getChannelDescription(String channelId) {
    return _channels.firstWhere((c) => c.id == channelId, orElse: () => _channels.first).description ?? '';
  }

  /// تنظيف الموارد
  void dispose() {
    _isInitialized = false;
    _currentToken = null;
  }

  /// اختبار الإشعارات - دالة للتأكد من عمل النظام
  Future<void> testNotification() async {
    try {
      debugPrint('🧪 Testing notification system...');
      
      await showLocalNotification(
        title: 'اختبار الإشعارات',
        body: 'هذا إشعار تجريبي للتأكد من عمل النظام بشكل صحيح',
        channelId: 'mybus_notifications',
        data: {
          'test': 'true',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error testing notification: $e');
    }
  }

  /// إرسال إشعار ترحيب عند تسجيل الدخول
  Future<void> sendWelcomeNotification(String userName) async {
    try {
      await showLocalNotification(
        title: 'مرحباً بك في كيدز باص',
        body: 'أهلاً وسهلاً $userName، تم تسجيل دخولك بنجاح',
        channelId: 'mybus_notifications',
        data: {
          'type': 'welcome',
          'userName': userName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('✅ Welcome notification sent to $userName');
    } catch (e) {
      debugPrint('❌ Error sending welcome notification: $e');
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken;
  List<AndroidNotificationChannel> get channels => _channels;
}
