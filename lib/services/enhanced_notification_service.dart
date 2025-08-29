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
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../utils/notification_images.dart' as NotificationUtils;
import 'unified_notification_service.dart';
import 'fcm_http_service.dart';
import 'global_notification_monitor.dart';

// تعريف UserRole للتوافق مع الكود
enum UserRole {
  parent,
  supervisor,
  admin,
}

/// خدمة الإشعارات المحسنة مع الصوت والإشعارات المحلية
/// تستخدم الخدمة الموحدة لتجنب التكرار
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final UnifiedNotificationService _unifiedService = UnifiedNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMHttpService _fcmHttpService = FCMHttpService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GlobalNotificationMonitor _globalMonitor = GlobalNotificationMonitor();
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة الخدمة الموحدة
      await _unifiedService.initialize();

      // بدء مراقبة الإشعارات العالمية
      await _globalMonitor.startMonitoring();

      _isInitialized = true;
      debugPrint('✅ Enhanced Notification Service initialized successfully with global monitoring');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  // تم نقل تهيئة الإشعارات المحلية إلى UnifiedNotificationService

  // تم نقل إنشاء قنوات الإشعارات إلى UnifiedNotificationService

  /// تهيئة Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    if (kIsWeb) return;

    // طلب الأذونات
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // الحصول على FCM token
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // معالجة الرسائل في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالجة الرسائل في الخلفية
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // معالجة النقر على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// معالجة الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    // التحقق من المستخدم المستهدف قبل عرض الإشعار
    final targetUserId = message.data['userId'] ?? message.data['recipientId'];
    final currentUser = FirebaseAuth.instance.currentUser;

    if (targetUserId != null && currentUser?.uid == targetUserId) {
      // عرض الإشعار فقط إذا كان المستخدم الحالي هو المستهدف
      debugPrint('✅ Showing notification for target user: $targetUserId');
      await _unifiedService.showLocalNotification(
        title: message.notification?.title ?? 'إشعار جديد',
        body: message.notification?.body ?? '',
        channelId: _getChannelId(message.data['type']),
        data: message.data,
        targetUserId: targetUserId,
      );
    } else {
      debugPrint('⚠️ Notification not for current user (${currentUser?.uid}), target: $targetUserId');
      debugPrint('📤 Notification skipped - not for current user');
    }
  }

  /// معالجة الرسائل في الخلفية
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.messageId}');
    // سيتم معالجة الإشعار تلقائياً بواسطة النظام
  }

  /// معالجة النقر على الإشعار
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.messageId}');
    // يمكن إضافة منطق التنقل هنا
  }

  /// معالجة النقر على الإشعار المحلي
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // يمكن إضافة منطق التنقل هنا
  }

  // تم نقل عرض الإشعارات المحلية إلى UnifiedNotificationService

  /// الحصول على معرف القناة بناءً على نوع الإشعار
  String _getChannelId(String? type) {
    switch (type) {
      case 'student':
        return 'student_notifications';
      case 'bus':
        return 'bus_notifications';
      case 'absence':
        return 'absence_notifications';
      case 'admin':
        return 'admin_notifications';
      case 'survey':
        return 'survey_notifications';
      case 'emergency':
        return 'emergency_notifications';
      default:
        return 'mybus_notifications';
    }
  }

  /// الحصول على اسم القناة
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'student_notifications':
        return 'إشعارات الطلاب';
      case 'bus_notifications':
        return 'إشعارات الباص';
      case 'absence_notifications':
        return 'إشعارات الغياب';
      case 'admin_notifications':
        return 'إشعارات الإدارة';
      case 'survey_notifications':
        return 'إشعارات الاستبيانات';
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
        return 'إشعارات ركوب ونزول الباص والرحلات';
      case 'absence_notifications':
        return 'إشعارات طلبات الغياب والموافقات';
      case 'admin_notifications':
        return 'إشعارات إدارية مهمة';
      case 'survey_notifications':
        return 'إشعارات الاستبيانات والاستطلاعات';
      case 'emergency_notifications':
        return 'تنبيهات طوارئ عاجلة ومهمة';
      default:
        return 'إشعارات عامة لتطبيق MyBus';
    }
  }



  /// إرسال إشعار لمستخدم محدد مع دعم الخلفية والصور
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // فحص محدد: منع الإشعارات للإدمن الحالي فقط إذا كان الإشعار متعلق بعمليات يقوم بها
      // ولكن فقط إذا كان المستخدم المستهدف هو إدمن أيضاً
      if (currentUser?.uid == userId &&
          type == 'student' &&
          data != null &&
          (data['type'] == 'student_data_update' ||
           data['action'] == 'student_assigned' ||
           data['action'] == 'student_unassigned')) {

        // التحقق من أن المستخدم المستهدف هو إدمن
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final userRole = userDoc.data()?['role'] ?? '';

        // منع الإشعار فقط إذا كان المستخدم إدمن
        if (userRole == 'admin') {
          debugPrint('⚠️ Skipping student-related notification for current admin: $userId');
          debugPrint('⚠️ Notification type: $type, Title: $title');
          return;
        } else {
          debugPrint('✅ Sending notification to parent (who is also current user): $userId');
        }
      }

      // حفظ الإشعار في قاعدة البيانات باستخدام الخدمة الموحدة
      await _unifiedService.saveNotificationToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      // تحسين العنوان والمحتوى
      final enhancedTitle = NotificationUtils.NotificationImages.getCustomTitle(type, title);
      final notificationImage = _getNotificationImage(type);
      final notificationIcon = _getNotificationIcon(type);

      // إرسال إشعار FCM حقيقي للمستخدم المستهدف مع صورة مميزة
      await _sendEnhancedFCMNotification(
        userId: userId,
        title: enhancedTitle,
        body: body,
        type: type,
        data: data,
        imageUrl: notificationImage,
        iconUrl: notificationIcon,
      );

      // إضافة للطابور العالمي للوصول من أي مكان
      await _queueForGlobalDelivery(
        userId: userId,
        title: enhancedTitle,
        body: body,
        type: type,
        data: data,
      );

      // إرسال إشعار محلي للمستخدم الحالي إذا كان هو المستهدف
      if (currentUser?.uid == userId) {
        debugPrint('📱 Sending enhanced local notification to current user: $userId');
        await _unifiedService.showLocalNotification(
          title: enhancedTitle,
          body: body,
          channelId: _getChannelId(type),
          imageUrl: notificationImage,
          iconUrl: notificationIcon,
          targetUserId: userId,
          data: {
            'type': type,
            'userId': userId,
            'recipientId': userId,
            'image': notificationImage,
            'icon': notificationIcon,
            ...?data?.map((key, value) => MapEntry(key, value.toString())),
          },
        );
      }

      debugPrint('✅ Enhanced notification sent to user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending enhanced notification: $e');
    }
  }

  /// إرسال إشعار FCM محسن مع صورة مميزة ودعم الخلفية
  Future<void> _sendEnhancedFCMNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? iconUrl,
  }) async {
    try {
      // الحصول على FCM Token للمستخدم المستهدف
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found: $userId');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ No FCM token found for user: $userId');
        return;
      }

      // استخدام الصور المرسلة أو الحصول عليها من النوع
      final notificationImage = imageUrl ?? _getNotificationImage(type);
      final notificationIcon = iconUrl ?? _getNotificationIcon(type);

      // إعداد بيانات الإشعار المحسن
      final enhancedData = {
        'type': type,
        'userId': userId,
        'recipientId': userId,
        'channelId': _getChannelId(type),
        'image': notificationImage,
        'icon': notificationIcon,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        ...?data?.map((key, value) => MapEntry(key, value.toString())),
      };

      // إرسال الإشعار عبر FCM HTTP Service مع الصورة
      final success = await _fcmHttpService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: enhancedData,
        channelId: _getChannelId(type),
        imageUrl: notificationImage,
        iconUrl: notificationIcon,
      );

      if (success) {
        debugPrint('✅ Enhanced FCM notification sent successfully to: $userId');
        debugPrint('🖼️ Image: $notificationImage');
        debugPrint('🎯 Icon: $notificationIcon');
      } else {
        debugPrint('❌ Failed to send enhanced FCM notification to: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error sending enhanced FCM notification: $e');
    }
  }

  /// الحصول على رابط الصورة حسب نوع الإشعار
  String _getNotificationImage(String type) {
    return NotificationUtils.NotificationImages.getNotificationImage(type);
  }

  /// الحصول على رابط الأيقونة حسب نوع الإشعار
  String _getNotificationIcon(String type) {
    return NotificationUtils.NotificationImages.getNotificationIcon(type);
  }

  /// إضافة الإشعار للطابور العالمي للوصول من أي مكان
  Future<void> _queueForGlobalDelivery({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // الحصول على FCM token للمستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ No FCM token for global delivery to user: $userId');
        return;
      }

      // إضافة للطابور العالمي
      await _globalMonitor.queueGlobalNotification(
        targetToken: fcmToken,
        title: title,
        body: body,
        userId: userId,
        data: {
          'type': type,
          'channelId': _getChannelId(type),
          ...?data?.map((key, value) => MapEntry(key, value.toString())),
        },
        channelId: _getChannelId(type),
      );

      debugPrint('✅ Notification queued for global delivery to: $userId');
    } catch (e) {
      debugPrint('❌ Error queuing for global delivery: $e');
    }
  }

  /// إرسال إشعار FCM مع notification payload
  Future<void> _sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 Sending real FCM notification to user: $userId');

      // إعداد بيانات الإشعار
      final notificationData = {
        'type': type,
        'channelId': _getChannelId(type),
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId,
        'targetUser': userId, // للتأكد من أن الإشعار للمستخدم المحدد فقط
        ...?data?.map((key, value) => MapEntry(key, value.toString())),
      };

      // إرسال إشعار FCM حقيقي للمستخدم المحدد فقط
      final success = await _fcmHttpService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: notificationData,
        channelId: _getChannelId(type),
      );

      if (success) {
        debugPrint('✅ Real FCM notification sent successfully to user: $userId');
      } else {
        debugPrint('❌ Failed to send FCM notification to user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }

  /// إرسال إشعار FCM حقيقي للمستخدم المحدد فقط
  Future<void> _sendRealFCMNotification({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
  }) async {
    try {
      // إرسال إشعار محلي فقط للمستخدم الحالي (للاختبار)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && data['userId'] == currentUser.uid) {
        await _sendLocalNotificationForCurrentUser(
          title: title,
          body: body,
          data: data,
          channelId: channelId,
        );
      }

      // في بيئة الإنتاج، هنا يجب إرسال إشعار FCM حقيقي للخادم
      // الذي سيرسل الإشعار للمستخدم المحدد فقط
      debugPrint('🔥 Real FCM notification would be sent to token: ${fcmToken.substring(0, 20)}...');
      debugPrint('📋 Notification data: $data');

    } catch (e) {
      debugPrint('❌ Error sending real FCM notification: $e');
    }
  }

  /// إرسال إشعار محلي للمستخدم الحالي فقط
  Future<void> _sendLocalNotificationForCurrentUser({
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

      await _unifiedService.showLocalNotification(
        title: title,
        body: body,
        channelId: channelId,
        data: data,
      );

      debugPrint('✅ Local notification displayed for current user: $title');
    } catch (e) {
      debugPrint('❌ Error sending local notification: $e');
    }
  }

  /// إرسال إشعار لمجموعة من المستخدمين
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    }
  }

  /// إرسال إشعار لجميع المستخدمين من نوع معين
  Future<void> sendNotificationToUserType({
    required UserRole userType,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 Sending notification to user type: ${userType.toString().split('.').last}');

      // إعداد بيانات الإشعار
      final notificationData = {
        'type': type,
        'channelId': _getChannelId(type),
        'timestamp': DateTime.now().toIso8601String(),
        'userType': userType.toString().split('.').last,
        ...?data?.map((key, value) => MapEntry(key, value.toString())),
      };

      // إرسال إشعار FCM حقيقي لجميع المستخدمين من النوع المحدد
      final results = await _fcmHttpService.sendNotificationToUserType(
        userType: userType.toString().split('.').last,
        title: title,
        body: body,
        data: notificationData,
        channelId: _getChannelId(type),
      );

      final successCount = results.where((result) => result).length;
      debugPrint('✅ Sent notifications to $successCount users of type: ${userType.toString().split('.').last}');
    } catch (e) {
      debugPrint('❌ Error sending notification to user type: $e');
    }
  }

  /// إرسال إشعار لجميع المستخدمين من نوع معين باستثناء مستخدم محدد
  Future<void> sendNotificationToUserTypeExcluding({
    required UserRole userType,
    String? excludeUserId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📤 Sending notification to user type: ${userType.toString().split('.').last} (excluding: $excludeUserId)');

      // الحصول على جميع المستخدمين من النوع المحدد
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: userType.toString().split('.').last)
          .get();

      // تصفية المستخدمين لاستبعاد المستخدم المحدد
      final allUserIds = usersQuery.docs.map((doc) => doc.id).toList();
      final userIds = allUserIds
          .where((userId) => excludeUserId == null || userId != excludeUserId)
          .toList();

      debugPrint('📊 Found ${allUserIds.length} total users, excluding $excludeUserId, sending to ${userIds.length} users');
      debugPrint('📊 All user IDs: $allUserIds');
      debugPrint('📊 Filtered user IDs: $userIds');

      if (userIds.isEmpty) {
        debugPrint('⚠️ No users found to notify after exclusion');
        return;
      }

      // إرسال الإشعارات للمستخدمين المتبقين
      await sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      debugPrint('✅ Sent notifications to ${userIds.length} users of type: ${userType.toString().split('.').last} (excluded: $excludeUserId)');
    } catch (e) {
      debugPrint('❌ Error sending notification to user type excluding: $e');
    }
  }

  /// حفظ FCM token للمستخدم
  Future<void> saveFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// إرسال إشعار اختبار FCM حقيقي للمستخدم الحالي
  Future<bool> sendTestFCMNotification() async {
    return await _fcmHttpService.sendTestNotificationToCurrentUser();
  }

  /// التحقق من صحة إعدادات FCM
  Future<bool> validateFCMSetup() async {
    return await _fcmHttpService.validateFCMSetup();
  }

  /// اختبار الإشعارات في مرحلة التطوير
  /// هذه الدالة لاختبار كيفية عمل الإشعارات للمستخدمين المختلفين
  Future<void> testNotificationForDifferentUser({
    required String targetUserId,
    required String title,
    required String body,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    debugPrint('🧪 Testing notification system:');
    debugPrint('👤 Current user: ${currentUser?.uid}');
    debugPrint('🎯 Target user: $targetUserId');

    if (currentUser?.uid == targetUserId) {
      debugPrint('✅ Target is current user - notification will show locally');
    } else {
      debugPrint('⚠️ Target is different user - notification saved to database only');
      debugPrint('📱 Target user will see notification when they open the app');
    }

    // إرسال الإشعار
    await sendNotificationToUser(
      userId: targetUserId,
      title: title,
      body: body,
      type: 'test',
      data: {
        'testMode': 'true',
        'sentBy': currentUser?.uid ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إرسال إشعار فوري للاختبار
  Future<bool> sendInstantTestNotification({
    required String title,
    required String body,
    String? channelId,
    Map<String, String>? data,
  }) async {
    return await _fcmHttpService.sendInstantTestNotification(
      title: title,
      body: body,
      channelId: channelId,
      data: data,
    );
  }

  /// الحصول على الإشعارات غير المقروءة للمستخدم
  Stream<List<NotificationModel>> getUnreadNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// تحديد الإشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// حذف الإشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  // ==================== إشعارات متخصصة ====================

  /// إشعار تسكين الطالب
  Future<void> notifyStudentAssignment({
    required String studentId,
    required String studentName,
    required String busId,
    required String busRoute,
    required String parentId,
    required String supervisorId,
    required String parentName,
    required String parentPhone,
    String? excludeAdminId, // استبعاد إدمن محدد من الإشعارات
  }) async {
    // إشعار ولي الأمر (فقط إذا لم يكن هو الإدمن الذي قام بالعملية)
    if (parentId.isNotEmpty && parentId != excludeAdminId) {
      await sendNotificationToUser(
        userId: parentId,
        title: '🚌 تم تسكين الطالب',
        body: 'تم تسكين $studentName في الباص رقم $busId - خط السير: $busRoute',
        type: 'student',
        data: {
          'studentId': studentId,
          'busId': busId,
          'action': 'student_assigned',
        },
      );
      debugPrint('✅ Parent notification sent for student assignment');
    } else {
      debugPrint('⚠️ Parent ID is empty or same as admin who made the assignment, skipping parent notification');
    }

    // إشعار المشرف (فقط إذا كان مختلف عن الإدمن)
    if (supervisorId.isNotEmpty && supervisorId != excludeAdminId) {
      await sendNotificationToUser(
        userId: supervisorId,
        title: '👨‍🏫 طالب جديد في الباص',
        body: 'تم إضافة الطالب $studentName إلى باصك\nولي الأمر: $parentName\nالهاتف: $parentPhone\nخط السير: $busRoute',
        type: 'student',
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'busId': busId,
          'parentId': parentId,
          'parentName': parentName,
          'parentPhone': parentPhone,
          'action': 'student_assigned',
        },
      );
    }

    // لا نرسل إشعارات للإدارة عند التسكين - فقط ولي الأمر والمشرف
    debugPrint('✅ Student assignment notifications sent to parent and supervisor only');
  }

  /// إشعار إلغاء تسكين الطالب
  Future<void> notifyStudentUnassignment({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
    String? excludeAdminId, // استبعاد إدمن محدد من الإشعارات
  }) async {
    // إشعار ولي الأمر (فقط إذا لم يكن هو الإدمن الذي قام بالعملية)
    if (parentId.isNotEmpty && parentId != excludeAdminId) {
      await sendNotificationToUser(
        userId: parentId,
        title: '🚫 تم إلغاء تسكين الطالب',
        body: 'تم إلغاء تسكين $studentName من الباص رقم $busId',
        type: 'student',
        data: {
          'studentId': studentId,
          'busId': busId,
          'action': 'student_unassigned',
        },
      );
      debugPrint('✅ Parent notification sent for student unassignment');
    } else {
      debugPrint('⚠️ Parent ID is empty or same as admin who made the unassignment, skipping parent notification');
    }

    // إشعار المشرف (فقط إذا لم يكن هو الإدمن)
    if (supervisorId.isNotEmpty && supervisorId != excludeAdminId) {
      await sendNotificationToUser(
        userId: supervisorId,
        title: '👋 مغادرة طالب',
        body: 'تم إزالة الطالب $studentName من باصك',
        type: 'student',
        data: {
          'studentId': studentId,
          'busId': busId,
          'action': 'student_unassigned',
        },
      );
      debugPrint('✅ Supervisor notification sent for student unassignment');
    } else {
      debugPrint('⚠️ Supervisor ID is empty or same as admin, skipping supervisor notification');
    }

    // لا نرسل إشعارات للإدارة عند إلغاء التسكين - فقط ولي الأمر والمشرف
    debugPrint('✅ Student unassignment notifications sent to parent and supervisor only');
  }

  /// إشعار ركوب الطالب الباص
  Future<void> notifyStudentBoarded({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
    required DateTime timestamp,
  }) async {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // إشعار ولي الأمر فقط
    await sendNotificationToUser(
      userId: parentId,
      title: '🚌 ركب الطالب الباص',
      body: '$studentName ركب الباص في الساعة $timeStr',
      type: 'bus',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_boarded',
        'timestamp': timestamp.toIso8601String(),
      },
    );

    // لا نرسل إشعار للإدارة عن ركوب الطلاب - هذا خاص بولي الأمر فقط
  }

  /// إشعار نزول الطالب من الباص
  Future<void> notifyStudentAlighted({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
    required DateTime timestamp,
  }) async {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // إشعار ولي الأمر فقط
    await sendNotificationToUser(
      userId: parentId,
      title: '🏠 نزل الطالب من الباص',
      body: '$studentName نزل من الباص في الساعة $timeStr',
      type: 'bus',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_alighted',
        'timestamp': timestamp.toIso8601String(),
      },
    );

    // لا نرسل إشعار للإدارة عن نزول الطلاب - هذا خاص بولي الأمر فقط
  }

  /// إشعار طلب غياب
  Future<void> notifyAbsenceRequest({
    required String studentId,
    required String studentName,
    required String parentId,
    required String parentName,
    required String supervisorId,
    required String busId,
    required DateTime absenceDate,
    required String reason,
  }) async {
    final dateStr = '${absenceDate.day}/${absenceDate.month}/${absenceDate.year}';

    // إشعار المشرف مع تفاصيل أكثر
    await sendNotificationToUser(
      userId: supervisorId,
      title: '📝 طلب غياب جديد',
      body: 'طلب غياب للطالب $studentName بتاريخ $dateStr\nولي الأمر: $parentName\nالسبب: $reason\nيرجى الموافقة أو الرفض',
      type: 'absence',
      data: {
        'studentId': studentId,
        'studentName': studentName,
        'parentId': parentId,
        'parentName': parentName,
        'busId': busId,
        'absenceDate': absenceDate.toIso8601String(),
        'reason': reason,
        'action': 'absence_requested',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '📝 طلب غياب جديد',
      body: 'طلب غياب للطالب $studentName من الباص $busId بتاريخ $dateStr\nولي الأمر: $parentName\nالسبب: $reason',
      type: 'absence',
      data: {
        'studentId': studentId,
        'studentName': studentName,
        'parentId': parentId,
        'parentName': parentName,
        'busId': busId,
        'supervisorId': supervisorId,
        'absenceDate': absenceDate.toIso8601String(),
        'reason': reason,
        'action': 'absence_requested',
      },
    );

    debugPrint('✅ Absence request notifications sent to supervisor and admins');
  }

  /// إشعار الموافقة على طلب الغياب
  Future<void> notifyAbsenceApproved({
    required String studentId,
    required String studentName,
    required String parentId,
    required String supervisorId,
    required DateTime absenceDate,
    required String approvedBy,
    String? approvedBySupervisorId, // معرف المشرف الذي وافق لاستبعاده
  }) async {
    final dateStr = '${absenceDate.day}/${absenceDate.month}/${absenceDate.year}';

    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '✅ تم قبول طلب الغياب',
      body: 'تم قبول طلب غياب $studentName بتاريخ $dateStr\nتمت الموافقة من: $approvedBy',
      type: 'absence',
      data: {
        'studentId': studentId,
        'studentName': studentName,
        'absenceDate': absenceDate.toIso8601String(),
        'action': 'absence_approved',
        'approvedBy': approvedBy,
      },
    );

    // إشعار المشرف (إذا لم يكن هو من وافق)
    if (supervisorId.isNotEmpty &&
        approvedBySupervisorId != null &&
        supervisorId != approvedBySupervisorId) {
      await sendNotificationToUser(
        userId: supervisorId,
        title: '✅ تم قبول طلب غياب',
        body: 'تم قبول طلب غياب الطالب $studentName بتاريخ $dateStr\nتمت الموافقة من: $approvedBy',
        type: 'absence',
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'absenceDate': absenceDate.toIso8601String(),
          'action': 'absence_approved',
          'approvedBy': approvedBy,
        },
      );
    }

    debugPrint('✅ Absence approval notifications sent');
  }

  /// إشعار رفض طلب الغياب
  Future<void> notifyAbsenceRejected({
    required String studentId,
    required String studentName,
    required String parentId,
    required String supervisorId,
    required DateTime absenceDate,
    required String rejectedBy,
    required String reason,
    String? rejectedBySupervisorId, // معرف المشرف الذي رفض لاستبعاده
  }) async {
    final dateStr = '${absenceDate.day}/${absenceDate.month}/${absenceDate.year}';

    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '❌ تم رفض طلب الغياب',
      body: 'تم رفض طلب غياب $studentName بتاريخ $dateStr\nالسبب: $reason\nتم الرفض من: $rejectedBy',
      type: 'absence',
      data: {
        'studentId': studentId,
        'studentName': studentName,
        'absenceDate': absenceDate.toIso8601String(),
        'action': 'absence_rejected',
        'rejectedBy': rejectedBy,
        'reason': reason,
      },
    );

    // إشعار المشرف (إذا لم يكن هو من رفض)
    if (supervisorId.isNotEmpty &&
        rejectedBySupervisorId != null &&
        supervisorId != rejectedBySupervisorId) {
      await sendNotificationToUser(
        userId: supervisorId,
        title: '❌ تم رفض طلب غياب',
        body: 'تم رفض طلب غياب الطالب $studentName بتاريخ $dateStr\nالسبب: $reason\nتم الرفض من: $rejectedBy',
        type: 'absence',
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'absenceDate': absenceDate.toIso8601String(),
          'action': 'absence_rejected',
          'rejectedBy': rejectedBy,
          'reason': reason,
        },
      );
    }

    debugPrint('✅ Absence rejection notifications sent');
  }

  /// إشعار تسجيل ولي أمر جديد
  Future<void> notifyNewParentRegistration({
    required String parentId,
    required String parentName,
    required String parentEmail,
    required String parentPhone,
    required DateTime registrationDate,
  }) async {
    final dateStr = '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}';

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '👨‍👩‍👧‍👦 تسجيل ولي أمر جديد',
      body: 'تم تسجيل ولي أمر جديد: $parentName\nالبريد: $parentEmail\nالهاتف: $parentPhone\nتاريخ التسجيل: $dateStr',
      type: 'admin',
      data: {
        'parentId': parentId,
        'parentName': parentName,
        'parentEmail': parentEmail,
        'parentPhone': parentPhone,
        'registrationDate': registrationDate.toIso8601String(),
        'action': 'parent_registered',
      },
    );

    debugPrint('✅ New parent registration notification sent to admins');
  }

  /// إشعار استبيان جديد
  Future<void> notifyNewSurvey({
    required String surveyId,
    required String surveyTitle,
    required String surveyDescription,
    required String createdBy,
    required DateTime deadline,
    required List<String> targetUserIds,
  }) async {
    final deadlineStr = '${deadline.day}/${deadline.month}/${deadline.year}';

    // إشعار المستخدمين المستهدفين
    await sendNotificationToUsers(
      userIds: targetUserIds,
      title: '📊 استبيان جديد',
      body: 'استبيان جديد: $surveyTitle\nالوصف: $surveyDescription\nآخر موعد للإجابة: $deadlineStr',
      type: 'survey',
      data: {
        'surveyId': surveyId,
        'surveyTitle': surveyTitle,
        'surveyDescription': surveyDescription,
        'createdBy': createdBy,
        'deadline': deadline.toIso8601String(),
        'action': 'survey_created',
      },
    );

    debugPrint('✅ New survey notification sent to ${targetUserIds.length} users');
  }

  /// إشعار انتهاء موعد الاستبيان
  Future<void> notifySurveyDeadlineReminder({
    required String surveyId,
    required String surveyTitle,
    required DateTime deadline,
    required List<String> pendingUserIds,
  }) async {
    final deadlineStr = '${deadline.day}/${deadline.month}/${deadline.year}';

    // إشعار المستخدمين الذين لم يجيبوا
    await sendNotificationToUsers(
      userIds: pendingUserIds,
      title: '⏰ تذكير: استبيان ينتهي قريباً',
      body: 'تذكير: استبيان "$surveyTitle" ينتهي في $deadlineStr\nيرجى الإجابة قبل انتهاء الموعد',
      type: 'survey',
      data: {
        'surveyId': surveyId,
        'surveyTitle': surveyTitle,
        'deadline': deadline.toIso8601String(),
        'action': 'survey_deadline_reminder',
      },
    );

    debugPrint('✅ Survey deadline reminder sent to ${pendingUserIds.length} users');
  }

  /// إشعار شكوى جديدة
  Future<void> notifyNewComplaint({
    required String complaintId,
    required String parentId,
    required String parentName,
    required String subject,
    required String category,
  }) async {
    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '📢 شكوى جديدة',
      body: 'شكوى جديدة من $parentName - الموضوع: $subject\nالفئة: $category',
      type: 'admin',
      data: {
        'complaintId': complaintId,
        'parentId': parentId,
        'parentName': parentName,
        'category': category,
        'action': 'complaint_submitted',
      },
    );

    debugPrint('✅ New complaint notification sent to admins');
  }

  /// إشعار رد على الشكوى
  Future<void> notifyComplaintResponse({
    required String complaintId,
    required String parentId,
    required String subject,
    required String response,
  }) async {
    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '💬 رد على الشكوى',
      body: 'تم الرد على شكواك: $subject',
      type: 'general',
      data: {
        'complaintId': complaintId,
        'action': 'complaint_responded',
      },
    );
  }

  /// إشعار تقييم المشرف للإدارة
  Future<void> notifySupervisorEvaluation({
    required String supervisorId,
    required String supervisorName,
    required String parentId,
    required String parentName,
    required String studentName,
    required double averageRating,
    String? comments,
  }) async {
    // تحديد مستوى التقييم
    String ratingText;
    String emoji;
    if (averageRating >= 4.5) {
      ratingText = 'ممتاز';
      emoji = '⭐';
    } else if (averageRating >= 3.5) {
      ratingText = 'جيد جداً';
      emoji = '👍';
    } else if (averageRating >= 2.5) {
      ratingText = 'جيد';
      emoji = '👌';
    } else if (averageRating >= 1.5) {
      ratingText = 'مقبول';
      emoji = '⚠️';
    } else {
      ratingText = 'ضعيف';
      emoji = '❌';
    }

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '$emoji تقييم جديد للمشرف',
      body: 'تقييم جديد للمشرف $supervisorName من $parentName\nالطالب: $studentName\nالتقييم: $ratingText (${averageRating.toStringAsFixed(1)}/5.0)${comments != null ? '\nتعليقات: $comments' : ''}',
      type: 'admin',
      data: {
        'supervisorId': supervisorId,
        'supervisorName': supervisorName,
        'parentId': parentId,
        'parentName': parentName,
        'studentName': studentName,
        'averageRating': averageRating,
        'ratingText': ratingText,
        'comments': comments,
        'action': 'supervisor_evaluation',
      },
    );

    debugPrint('✅ Supervisor evaluation notification sent to admins');
  }

  /// إشعار تحديث حالة الرحلة
  Future<void> notifyTripStatusUpdate({
    required String busId,
    required String busRoute,
    required String status,
    required List<String> parentIds,
    required String supervisorId,
  }) async {
    String statusText;
    String emoji;

    switch (status) {
      case 'started':
        statusText = 'بدأت الرحلة';
        emoji = '🚌';
        break;
      case 'completed':
        statusText = 'انتهت الرحلة';
        emoji = '✅';
        break;
      case 'delayed':
        statusText = 'تأخرت الرحلة';
        emoji = '⏰';
        break;
      default:
        statusText = 'تحديث حالة الرحلة';
        emoji = '📍';
    }

    // إشعار أولياء الأمور
    await sendNotificationToUsers(
      userIds: parentIds,
      title: '$emoji $statusText',
      body: 'الباص $busId - خط السير: $busRoute',
      type: 'bus',
      data: {
        'busId': busId,
        'status': status,
        'action': 'trip_status_update',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '$emoji تحديث حالة الرحلة',
      body: 'الباص $busId - $statusText',
      type: 'admin',
      data: {
        'busId': busId,
        'status': status,
        'supervisorId': supervisorId,
        'action': 'trip_status_update',
      },
    );
  }

  /// إشعار تعيين مشرف جديد للباص
  Future<void> notifyNewSupervisorAssignment({
    required String supervisorId,
    required String supervisorName,
    required String busId,
    required String busRoute,
    required String assignedBy,
  }) async {
    // إشعار المشرف الجديد
    await sendNotificationToUser(
      userId: supervisorId,
      title: '🚌 تم تعيينك مشرف باص',
      body: 'تم تعيينك مشرف للباص رقم $busId\nخط السير: $busRoute\nتم التعيين من: $assignedBy',
      type: 'admin',
      data: {
        'busId': busId,
        'busRoute': busRoute,
        'assignedBy': assignedBy,
        'action': 'supervisor_assigned',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '👨‍🏫 تم تعيين مشرف جديد',
      body: 'تم تعيين $supervisorName مشرف للباص $busId',
      type: 'admin',
      data: {
        'supervisorId': supervisorId,
        'supervisorName': supervisorName,
        'busId': busId,
        'busRoute': busRoute,
        'action': 'supervisor_assigned',
      },
    );

    debugPrint('✅ New supervisor assignment notifications sent');
  }

  /// إشعار تحديث جدول الرحلات
  Future<void> notifyScheduleUpdate({
    required String busId,
    required String busRoute,
    required String supervisorId,
    required List<String> parentIds,
    required String updatedBy,
    required Map<String, dynamic> scheduleChanges,
  }) async {
    // إشعار المشرف
    await sendNotificationToUser(
      userId: supervisorId,
      title: '📅 تحديث جدول الرحلات',
      body: 'تم تحديث جدول رحلات الباص $busId\nخط السير: $busRoute\nيرجى مراجعة الجدول الجديد',
      type: 'admin',
      data: {
        'busId': busId,
        'busRoute': busRoute,
        'updatedBy': updatedBy,
        'action': 'schedule_updated',
      },
    );

    // إشعار أولياء الأمور
    await sendNotificationToUsers(
      userIds: parentIds,
      title: '📅 تحديث جدول الرحلات',
      body: 'تم تحديث جدول رحلات الباص $busId\nخط السير: $busRoute\nيرجى مراجعة الجدول الجديد',
      type: 'admin',
      data: {
        'busId': busId,
        'busRoute': busRoute,
        'action': 'schedule_updated',
      },
    );

    debugPrint('✅ Schedule update notifications sent to supervisor and ${parentIds.length} parents');
  }

  /// إشعار طوارئ
  Future<void> notifyEmergency({
    required String busId,
    required String supervisorId,
    required String supervisorName,
    required String emergencyType,
    required String description,
    required List<String> parentIds,
  }) async {
    // إشعار أولياء الأمور
    await sendNotificationToUsers(
      userIds: parentIds,
      title: '🚨 حالة طوارئ',
      body: 'حالة طوارئ في الباص $busId - $emergencyType\nالوصف: $description\nيرجى التواصل مع الإدارة فوراً',
      type: 'emergency',
      data: {
        'busId': busId,
        'supervisorId': supervisorId,
        'emergencyType': emergencyType,
        'description': description,
        'action': 'emergency',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '🚨 حالة طوارئ عاجلة',
      body: 'حالة طوارئ من المشرف $supervisorName في الباص $busId\nالنوع: $emergencyType\nالوصف: $description\nيرجى التدخل فوراً',
      type: 'emergency',
      data: {
        'busId': busId,
        'supervisorId': supervisorId,
        'supervisorName': supervisorName,
        'emergencyType': emergencyType,
        'description': description,
        'action': 'emergency',
      },
    );

    debugPrint('✅ Emergency notifications sent to ${parentIds.length} parents and admins');
  }

  /// إشعار تحديث بيانات الطالب لولي الأمر والمشرف والإدارة
  Future<void> notifyStudentDataUpdate({
    required String studentId,
    required String studentName,
    required String parentId,
    required String busId,
    required Map<String, dynamic> updatedFields,
    required String adminName,
    String? adminId, // معرف الإدمن الذي قام بالتحديث لاستبعاده من الإشعارات
  }) async {
    try {
      debugPrint('🔔 Sending student data update notifications for: $studentName');
      debugPrint('🔍 Debug info:');
      debugPrint('   - Student ID: $studentId');
      debugPrint('   - Parent ID: $parentId');
      debugPrint('   - Admin ID: $adminId');
      debugPrint('   - Current User: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('   - Bus ID: $busId');

      // إنشاء رسالة التحديث
      final updatedFieldsText = _formatUpdatedFields(updatedFields);

      // إشعار ولي الأمر
      await _notifyParentOfStudentUpdate(
        parentId: parentId,
        studentName: studentName,
        updatedFields: updatedFieldsText,
        adminName: adminName,
        adminId: adminId, // تمرير معرف الإدمن لاستبعاده
      );

      // إشعار المشرف (إذا كان الطالب مسكن في باص وليس نفس الإدمن)
      if (busId.isNotEmpty) {
        await _notifySupervisorOfStudentUpdate(
          busId: busId,
          studentName: studentName,
          updatedFields: updatedFieldsText,
          adminName: adminName,
          adminId: adminId, // تمرير معرف الإدمن لاستبعاده
        );
      }

      // لا نرسل إشعارات للإدمن الآخرين لتجنب الإزعاج
      // فقط ولي الأمر والمشرف يحتاجون للإشعار
      debugPrint('✅ Student data update notifications sent to parent and supervisor only');

      debugPrint('✅ Student data update notifications sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending student data update notifications: $e');
    }
  }

  /// إشعار ولي الأمر بتحديث بيانات الطالب
  Future<void> _notifyParentOfStudentUpdate({
    required String parentId,
    required String studentName,
    required String updatedFields,
    required String adminName,
    String? adminId, // إضافة معرف الإدمن لاستبعاده
  }) async {
    try {
      // التحقق من أن ولي الأمر ليس هو الإدمن الذي قام بالتحديث
      if (parentId.isEmpty) {
        debugPrint('⚠️ Parent ID is empty, skipping parent notification');
        return;
      }

      if (adminId != null && parentId == adminId) {
        debugPrint('⚠️ Parent is the same as admin who made the update, skipping parent notification');
        return;
      }

      final title = 'تحديث بيانات الطالب';
      final body = 'تم تحديث بيانات الطالب $studentName من قبل الإدارة\n\nالتحديثات:\n$updatedFields';

      await sendNotificationToUser(
        userId: parentId,
        title: title,
        body: body,
        type: 'student',
        data: {
          'type': 'student_data_update',
          'studentName': studentName,
          'updatedBy': adminName,
          'updatedFields': updatedFields,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Parent notification sent for student data update');
    } catch (e) {
      debugPrint('❌ Error sending parent notification: $e');
    }
  }

  /// إشعار المشرف بتحديث بيانات الطالب
  Future<void> _notifySupervisorOfStudentUpdate({
    required String busId,
    required String studentName,
    required String updatedFields,
    required String adminName,
    String? adminId, // معرف الإدمن لاستبعاده
  }) async {
    try {
      // الحصول على المشرف المسؤول عن الباص
      final supervisorId = await _getActiveSupervisorForBus(busId);

      // إرسال الإشعار فقط إذا كان المشرف مختلف عن الإدمن
      if (supervisorId != null && supervisorId != adminId) {
        final title = 'تحديث بيانات طالب في الباص';
        final body = 'تم تحديث بيانات الطالب $studentName في الباص الخاص بك\n\nالتحديثات:\n$updatedFields';

        await sendNotificationToUser(
          userId: supervisorId,
          title: title,
          body: body,
          type: 'student',
          data: {
            'type': 'student_data_update',
            'studentName': studentName,
            'busId': busId,
            'updatedBy': adminName,
            'updatedFields': updatedFields,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        debugPrint('✅ Supervisor notification sent for student data update');
      } else if (supervisorId == adminId) {
        debugPrint('⚠️ Supervisor is the same as admin, skipping notification');
      } else {
        debugPrint('⚠️ No active supervisor found for bus: $busId');
      }
    } catch (e) {
      debugPrint('❌ Error sending supervisor notification: $e');
    }
  }

  /// إشعار الإدارة الأخرى بتحديث بيانات الطالب (باستثناء الإدمن الذي قام بالتحديث)
  Future<void> _notifyAdminsOfStudentUpdate({
    required String studentName,
    required String updatedFields,
    required String adminName,
    String? adminId, // معرف الإدمن لاستبعاده من الإشعارات
  }) async {
    try {
      final title = '📝 تم تحديث بيانات طالب';
      final body = 'تم تحديث بيانات الطالب $studentName بواسطة $adminName\n\nالتحديثات:\n$updatedFields';

      await sendNotificationToUserTypeExcluding(
        userType: UserRole.admin,
        excludeUserId: adminId,
        title: title,
        body: body,
        type: 'admin',
        data: {
          'type': 'student_data_update',
          'studentName': studentName,
          'updatedBy': adminName,
          'updatedFields': updatedFields,
          'timestamp': DateTime.now().toIso8601String(),
          'action': 'student_data_updated',
        },
      );

      debugPrint('✅ Admin notifications sent for student data update (excluding: $adminId)');
    } catch (e) {
      debugPrint('❌ Error sending admin notifications: $e');
    }
  }

  /// الحصول على المشرف النشط للباص
  Future<String?> _getActiveSupervisorForBus(String busId) async {
    try {
      final querySnapshot = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['supervisorId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting active supervisor for bus: $e');
      return null;
    }
  }

  /// تنسيق الحقول المحدثة لعرضها في الإشعار
  String _formatUpdatedFields(Map<String, dynamic> updatedFields) {
    final List<String> formattedFields = [];

    updatedFields.forEach((key, value) {
      final fieldName = _getFieldDisplayName(key);
      final oldValue = value['old']?.toString() ?? 'غير محدد';
      final newValue = value['new']?.toString() ?? 'غير محدد';

      if (oldValue != newValue) {
        formattedFields.add('• $fieldName: من "$oldValue" إلى "$newValue"');
      }
    });

    return formattedFields.isEmpty ? 'لا توجد تغييرات' : formattedFields.join('\n');
  }

  /// الحصول على اسم الحقل باللغة العربية
  String _getFieldDisplayName(String fieldKey) {
    switch (fieldKey) {
      case 'name':
        return 'اسم الطالب';
      case 'schoolName':
        return 'اسم المدرسة';
      case 'grade':
        return 'الصف';
      case 'busId':
        return 'الباص المخصص';
      case 'parentName':
        return 'اسم ولي الأمر';
      case 'parentPhone':
        return 'رقم هاتف ولي الأمر';
      case 'address':
        return 'العنوان';
      case 'notes':
        return 'ملاحظات';
      case 'currentStatus':
        return 'الحالة الحالية';
      default:
        return fieldKey;
    }
  }

  /// إشعار تفعيل الحافلة
  Future<void> notifyBusActivation({
    required String busId,
    required String busPlateNumber,
    required String driverName,
    required String adminName,
    String? adminId,
  }) async {
    try {
      debugPrint('🔔 Sending bus activation notifications for: $busPlateNumber');

      // إشعار المشرف المعين للحافلة
      await _notifySupervisorOfBusActivation(
        busId: busId,
        busPlateNumber: busPlateNumber,
        driverName: driverName,
        adminName: adminName,
        adminId: adminId,
      );

      debugPrint('✅ Bus activation notifications sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending bus activation notifications: $e');
    }
  }

  /// إشعار المشرف بتفعيل الحافلة
  Future<void> _notifySupervisorOfBusActivation({
    required String busId,
    required String busPlateNumber,
    required String driverName,
    required String adminName,
    String? adminId,
  }) async {
    try {
      final supervisorId = await _getActiveSupervisorForBus(busId);

      if (supervisorId != null && supervisorId != adminId) {
        await sendNotificationToUser(
          userId: supervisorId,
          title: '🚌 تم تفعيل الحافلة',
          body: 'تم تفعيل الحافلة $busPlateNumber\nالسائق: $driverName\nيمكنك الآن بدء الرحلات',
          type: 'admin',
          data: {
            'busId': busId,
            'busPlateNumber': busPlateNumber,
            'driverName': driverName,
            'action': 'bus_activated',
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error notifying supervisor of bus activation: $e');
    }
  }

  /// إشعار إيقاف الحافلة
  Future<void> notifyBusDeactivation({
    required String busId,
    required String busPlateNumber,
    required String driverName,
    required String adminName,
    String? adminId,
  }) async {
    try {
      debugPrint('🔔 Sending bus deactivation notifications for: $busPlateNumber');

      // إشعار المشرف المعين للحافلة
      final supervisorId = await _getActiveSupervisorForBus(busId);
      if (supervisorId != null && supervisorId != adminId) {
        await sendNotificationToUser(
          userId: supervisorId,
          title: '⚠️ تم إيقاف الحافلة',
          body: 'تم إيقاف الحافلة $busPlateNumber (السائق: $driverName) من قبل $adminName\n\nيرجى التوقف عن العمليات والرحلات',
          type: 'admin',
          data: {
            'busId': busId,
            'busPlateNumber': busPlateNumber,
            'driverName': driverName,
            'deactivatedBy': adminName,
            'action': 'bus_deactivated',
          },
        );
      }

      // إشعار أولياء أمور الطلاب المسكنين في الحافلة
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('busId', isEqualTo: busId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final parentId = studentData['parentId'];
        final studentName = studentData['name'] ?? 'الطالب';

        if (parentId != null && parentId.isNotEmpty && parentId != adminId) {
          await sendNotificationToUser(
            userId: parentId,
            title: '⚠️ تم إيقاف حافلة طفلك',
            body: 'تم إيقاف الحافلة $busPlateNumber الخاصة بـ $studentName مؤقتاً\n\nيرجى ترتيب وسيلة نقل بديلة',
            type: 'student',
            data: {
              'busId': busId,
              'busPlateNumber': busPlateNumber,
              'studentName': studentName,
              'deactivatedBy': adminName,
              'action': 'bus_deactivated',
            },
          );
        }
      }

      debugPrint('✅ Bus deactivation notifications sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending bus deactivation notifications: $e');
    }
  }

  /// إشعار ترحيبي محسن لولي الأمر الجديد
  Future<void> sendWelcomeNotificationToNewParent({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      debugPrint('🎉 Sending enhanced welcome notification to new parent: $parentName');

      // إشعار ترحيبي أساسي
      await sendNotificationToUser(
        userId: parentId,
        title: '🎉 أهلاً وسهلاً بك في MyBus',
        body: 'مرحباً $parentName! تم إنشاء حسابك بنجاح. استمتع بمتابعة رحلة طفلك بأمان.',
        type: 'welcome',
        data: {
          'type': 'welcome_notification',
          'parentId': parentId,
          'parentName': parentName,
          'action': 'welcome',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // انتظار قصير ثم إرسال إشعار تعليمات
      await Future.delayed(Duration(seconds: 5));

      await sendNotificationToUser(
        userId: parentId,
        title: '📱 كيفية استخدام التطبيق',
        body: 'يمكنك الآن متابعة رحلة طفلك، طلب الغياب، والتواصل مع المشرف. اضغط هنا للمزيد.',
        type: 'tutorial',
        data: {
          'type': 'app_tutorial',
          'parentId': parentId,
          'action': 'show_tutorial',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // انتظار قصير ثم إرسال إشعار الدعم
      await Future.delayed(Duration(seconds: 10));

      await sendNotificationToUser(
        userId: parentId,
        title: '🆘 الدعم والمساعدة',
        body: 'إذا كان لديك أي استفسار، يمكنك التواصل معنا في أي وقت. نحن هنا لمساعدتك!',
        type: 'support',
        data: {
          'type': 'support_info',
          'parentId': parentId,
          'action': 'show_support',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Enhanced welcome notifications sent to new parent: $parentName');
    } catch (e) {
      debugPrint('❌ Error sending welcome notification to new parent: $e');
    }
  }

  /// إشعار ترحيبي سريع لولي الأمر الجديد
  Future<void> sendQuickWelcomeNotification({
    required String parentId,
    required String parentName,
  }) async {
    try {
      debugPrint('🎉 Sending quick welcome notification to: $parentName');

      await sendNotificationToUser(
        userId: parentId,
        title: '🎉 مرحباً بك في MyBus',
        body: 'أهلاً وسهلاً $parentName! تم تسجيل حسابك بنجاح. نحن سعداء لانضمامك إلى عائلة MyBus.',
        type: 'welcome',
        data: {
          'type': 'quick_welcome',
          'parentId': parentId,
          'parentName': parentName,
          'action': 'welcome',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Quick welcome notification sent to: $parentName');
    } catch (e) {
      debugPrint('❌ Error sending quick welcome notification: $e');
    }
  }
}
