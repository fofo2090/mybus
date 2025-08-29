import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_notification_model.dart';
import '../widgets/admin_notification_dialog.dart';
import '../models/notification_model.dart';
import 'fcm_http_service.dart';

/// خدمة الإشعارات المتقدمة للأدمن
/// تعرض dialog جميل ثم تحفظ في قائمة الإشعارات المحلية
class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // مفتاح حفظ الإشعارات المحلية
  static const String _notificationsKey = 'admin_local_notifications';
  static const String _unreadCountKey = 'admin_unread_count';

  // Context للعرض
  BuildContext? _context;

  // قائمة الإشعارات المحلية
  List<AdminNotificationModel> _localNotificationsList = [];
  
  // عداد الإشعارات غير المقروءة
  int _unreadCount = 0;
  
  // Stream controller للإشعارات
  final StreamController<List<AdminNotificationModel>> _notificationsController =
      StreamController<List<AdminNotificationModel>>.broadcast();

  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  // متغير لتتبع حالة التهيئة
  bool _isInitialized = false;

  /// تهيئة الخدمة
  Future<void> initialize([BuildContext? context]) async {
    if (_isInitialized) {
      // إذا كانت الخدمة مهيأة، أرسل البيانات الحالية للـ streams
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);
      return;
    }

    if (context != null) {
      _context = context;
    }

    try {
      debugPrint('🔔 تهيئة خدمة إشعارات الأدمن...');

      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // تحميل الإشعارات المحفوظة
      await _loadSavedNotifications();

      // إزالة الإشعارات المكررة
      await removeDuplicateNotifications();

      // إعداد معالجات الرسائل
      _setupMessageHandlers();

      // إرسال البيانات الأولية للـ streams
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة إشعارات الأدمن بنجاح');
      debugPrint('📊 عدد الإشعارات المحملة: ${_localNotificationsList.length}');
      debugPrint('📊 عدد الإشعارات غير المقروءة: $_unreadCount');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة إشعارات الأدمن: $e');
      // في حالة الخطأ، أرسل قوائم فارغة
      _notificationsController.add([]);
      _unreadCountController.add(0);
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
    
    await _flutterLocalNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قناة الإشعارات للأندرويد
    const androidChannel = AndroidNotificationChannel(
      'admin_notifications',
      'إشعارات الأدمن',
      description: 'إشعارات خاصة بالأدمن',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _flutterLocalNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// إعداد معالجات الرسائل
  void _setupMessageHandlers() {
    // معالج الرسائل عندما يكون التطبيق نشط
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // معالج الرسائل عندما يكون التطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // معالج الرسائل عند فتح التطبيق من إشعار
    _handleInitialMessage();
  }

  /// معالجة الرسائل عندما يكون التطبيق نشط
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 إشعار جديد للأدمن (التطبيق نشط): ${message.notification?.title}');
    
    // التحقق من أن المستخدم الحالي هو أدمن
    if (!_isCurrentUserAdmin()) return;
    
    // إنشاء نموذج الإشعار
    final notification = _createNotificationModel(message);
    
    // عرض Dialog جميل
    await _showNotificationDialog(notification);
    
    // حفظ في القائمة المحلية
    await _saveNotificationLocally(notification);
    
    // عرض إشعار في شريط الإشعارات
    await _showLocalNotification(notification);
  }

  /// معالجة الرسائل عندما يكون التطبيق في الخلفية
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 إشعار جديد للأدمن (من الخلفية): ${message.notification?.title}');
    
    if (!_isCurrentUserAdmin()) return;
    
    final notification = _createNotificationModel(message);
    await _saveNotificationLocally(notification);
  }

  /// معالجة الرسالة الأولية عند فتح التطبيق
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleBackgroundMessage(initialMessage);
    }
  }

  /// التحقق من أن المستخدم الحالي أدمن
  bool _isCurrentUserAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    // يمكن إضافة منطق أكثر تعقيداً للتحقق من نوع المستخدم
    return user != null;
  }

  /// إنشاء نموذج الإشعار من RemoteMessage
  AdminNotificationModel _createNotificationModel(RemoteMessage message) {
    // إنشاء ID فريد يتضمن hash للمحتوى لتجنب التكرار
    final contentHash = (message.notification?.title ?? '').hashCode ^
                       (message.notification?.body ?? '').hashCode;
    final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_$contentHash';

    return AdminNotificationModel(
      id: uniqueId,
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'general',
      priority: _getPriorityFromData(message.data),
    );
  }

  /// تحديد أولوية الإشعار
  NotificationPriority _getPriorityFromData(Map<String, dynamic> data) {
    final priority = data['priority']?.toString().toLowerCase();
    switch (priority) {
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }

  /// عرض Dialog جميل للإشعار
  Future<void> _showNotificationDialog(AdminNotificationModel notification) async {
    if (_context == null) return;

    // اهتزاز خفيف
    HapticFeedback.lightImpact();

    return showDialog(
      context: _context!,
      barrierDismissible: true,
      builder: (context) => AdminNotificationDialog(
        notification: notification,
        onDismiss: () => Navigator.of(context).pop(),
        onMarkAsRead: () => markAsRead(notification.id),
      ),
    );
  }

  /// حفظ الإشعار محلياً
  Future<void> _saveNotificationLocally(AdminNotificationModel notification) async {
    try {
      // التحقق من عدم وجود إشعار مكرر
      final existingIndex = _localNotificationsList.indexWhere((existing) =>
        existing.id == notification.id ||
        (existing.title == notification.title &&
         existing.body == notification.body &&
         existing.timestamp.difference(notification.timestamp).abs().inSeconds < 5)
      );

      if (existingIndex != -1) {
        debugPrint('⚠️ إشعار مكرر تم تجاهله: ${notification.title}');
        return;
      }

      _localNotificationsList.insert(0, notification);

      // الاحتفاظ بآخر 100 إشعار فقط
      if (_localNotificationsList.length > 100) {
        _localNotificationsList = _localNotificationsList.take(100).toList();
      }

      // زيادة عداد غير المقروءة
      _unreadCount++;

      // حفظ في SharedPreferences
      await _saveToPreferences();

      // إشعار المستمعين
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);

      debugPrint('💾 تم حفظ الإشعار محلياً: ${notification.title}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإشعار: $e');
    }
  }

  /// عرض إشعار في شريط الإشعارات (محسن للظهور خارج التطبيق)
  Future<void> _showLocalNotification(AdminNotificationModel notification) async {
    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // إعدادات Android محسنة للظهور خارج التطبيق
      final androidDetails = AndroidNotificationDetails(
        'admin_notifications',
        'إشعارات الأدمن',
        channelDescription: 'إشعارات خاصة بالأدمن',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        icon: '@mipmap/launcher_icon', // استخدام أيقونة التطبيق الرئيسية
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        color: const Color(0xFF1E88E5),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        autoCancel: true,
        ongoing: false,
        silent: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
        ticker: '${notification.title} - ${notification.body}',
        groupKey: 'com.mybus.admin_notifications',
        // إضافة نمط النص الكبير
        styleInformation: BigTextStyleInformation(
          notification.body,
          htmlFormatBigText: false,
          contentTitle: notification.title,
          htmlFormatContentTitle: false,
          summaryText: 'كيدز باص - إدارة',
          htmlFormatSummaryText: false,
        ),
        // إعدادات إضافية للظهور
        category: AndroidNotificationCategory.message,
        setAsGroupSummary: false,
        groupAlertBehavior: GroupAlertBehavior.all,
      );

      // إعدادات iOS محسنة
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.mp3',
        subtitle: 'كيدز باص - إدارة',
        threadIdentifier: 'admin_notifications',
        categoryIdentifier: 'admin_category',
        badgeNumber: 1,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(notification.toMap()),
      );

      debugPrint('✅ Enhanced admin notification shown: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Error showing enhanced admin notification: $e');
    }
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notification = AdminNotificationModel.fromMap(data);
        markAsRead(notification.id);
        
        // يمكن إضافة منطق للانتقال لصفحة معينة حسب نوع الإشعار
        debugPrint('🔔 تم النقر على الإشعار: ${notification.title}');
      } catch (e) {
        debugPrint('❌ خطأ في معالجة النقر على الإشعار: $e');
      }
    }
  }

  /// تحميل الإشعارات المحفوظة
  Future<void> _loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
      final unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
      
      _localNotificationsList = notificationsJson
          .map((json) => AdminNotificationModel.fromMap(jsonDecode(json)))
          .toList();

      _unreadCount = unreadCount;

      // إشعار المستمعين
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);

      debugPrint('📂 تم تحميل ${_localNotificationsList.length} إشعار محفوظ');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الإشعارات: $e');
    }
  }

  /// حفظ في SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _localNotificationsList
          .map((notification) => jsonEncode(notification.toMap()))
          .toList();
      
      await prefs.setStringList(_notificationsKey, notificationsJson);
      await prefs.setInt(_unreadCountKey, _unreadCount);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإشعارات: $e');
    }
  }

  /// تحديد الإشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    final index = _localNotificationsList.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_localNotificationsList[index].isRead) {
      _localNotificationsList[index] = _localNotificationsList[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _localNotificationsList.length);

      await _saveToPreferences();
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _localNotificationsList.length; i++) {
      _localNotificationsList[i] = _localNotificationsList[i].copyWith(isRead: true);
    }
    _unreadCount = 0;

    await _saveToPreferences();
    _notificationsController.add(_localNotificationsList);
    _unreadCountController.add(_unreadCount);
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    final index = _localNotificationsList.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      if (!_localNotificationsList[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _localNotificationsList.length);
      }
      _localNotificationsList.removeAt(index);

      await _saveToPreferences();
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);
    }
  }

  /// مسح جميع الإشعارات
  Future<void> clearAllNotifications() async {
    _localNotificationsList.clear();
    _unreadCount = 0;

    await _saveToPreferences();
    _notificationsController.add(_localNotificationsList);
    _unreadCountController.add(_unreadCount);
  }

  /// إزالة الإشعارات المكررة
  Future<void> removeDuplicateNotifications() async {
    final uniqueNotifications = <AdminNotificationModel>[];
    final seenIds = <String>{};
    final seenContent = <String>{};

    for (final notification in _localNotificationsList) {
      final contentKey = '${notification.title}_${notification.body}';

      if (!seenIds.contains(notification.id) && !seenContent.contains(contentKey)) {
        uniqueNotifications.add(notification);
        seenIds.add(notification.id);
        seenContent.add(contentKey);
      } else {
        debugPrint('🗑️ إزالة إشعار مكرر: ${notification.title}');
        // تقليل العداد إذا كان الإشعار المكرر غير مقروء
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, _localNotificationsList.length);
        }
      }
    }

    if (uniqueNotifications.length != _localNotificationsList.length) {
      _localNotificationsList = uniqueNotifications;
      await _saveToPreferences();
      _notificationsController.add(_localNotificationsList);
      _unreadCountController.add(_unreadCount);

      debugPrint('✅ تم إزالة ${_localNotificationsList.length - uniqueNotifications.length} إشعار مكرر');
    }
  }

  /// إضافة إشعارات تجريبية للاختبار
  Future<void> addTestNotifications() async {
    // التحقق من وجود إشعارات تجريبية مسبقاً
    final hasTestNotifications = _localNotificationsList.any((notification) =>
      notification.id.startsWith('test_'));

    if (hasTestNotifications) {
      debugPrint('📝 الإشعارات التجريبية موجودة بالفعل، لن يتم إضافة إشعارات جديدة');
      return;
    }

    final testNotifications = [
      AdminNotificationModel(
        id: 'test_1',
        title: 'شكوى جديدة',
        body: 'تم تقديم شكوى جديدة من ولي أمر الطالب أحمد محمد',
        type: 'complaint',
        priority: NotificationPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        data: {'complaintId': 'comp_001', 'studentName': 'أحمد محمد'},
      ),
      AdminNotificationModel(
        id: 'test_2',
        title: 'طلب غياب جديد',
        body: 'طلب غياب جديد للطالبة سارة علي يحتاج موافقة',
        type: 'absence',
        priority: NotificationPriority.normal,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        data: {'absenceId': 'abs_001', 'studentName': 'سارة علي'},
      ),
      AdminNotificationModel(
        id: 'test_3',
        title: 'تقرير يومي',
        body: 'تقرير الرحلات اليومية جاهز للمراجعة',
        type: 'report',
        priority: NotificationPriority.low,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        data: {'reportType': 'daily', 'date': DateTime.now().toIso8601String()},
      ),
      AdminNotificationModel(
        id: 'test_4',
        title: 'تنبيه أمان',
        body: 'تم الإبلاغ عن حادث بسيط في الحافلة رقم 123',
        type: 'safety',
        priority: NotificationPriority.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
        data: {'busNumber': '123', 'incidentType': 'minor'},
      ),
      AdminNotificationModel(
        id: 'test_5',
        title: 'مستخدم جديد',
        body: 'تم تسجيل ولي أمر جديد في النظام',
        type: 'user',
        priority: NotificationPriority.low,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
        data: {'userId': 'user_001', 'userType': 'parent'},
      ),
    ];

    for (final notification in testNotifications) {
      await _saveNotificationLocally(notification);
    }

    debugPrint('✅ تم إضافة ${testNotifications.length} إشعار تجريبي');
  }

  /// إضافة إشعار جديد يدوياً (محسن للظهور خارج التطبيق)
  Future<void> addNotification(AdminNotificationModel notification) async {
    await _saveNotificationLocally(notification);

    // عرض الإشعار في شريط الإشعارات (محسن)
    await _showLocalNotification(notification);

    // إرسال إشعار FCM حقيقي للأدمن
    await _sendRealFCMNotification(notification);

    debugPrint('✅ تم إضافة إشعار جديد محسن: ${notification.title}');
  }

  /// إرسال إشعار FCM حقيقي للأدمن
  Future<void> _sendRealFCMNotification(AdminNotificationModel notification) async {
    try {
      // استخدام FCMHttpService لإرسال إشعار حقيقي
      final fcmHttpService = FCMHttpService();

      // الحصول على جميع الأدمن
      final adminUsers = await _getAdminUsers();

      if (adminUsers.isEmpty) {
        debugPrint('⚠️ No admin users found for FCM notification');
        return;
      }

      // إرسال الإشعار لجميع الأدمن
      for (final adminId in adminUsers) {
        await fcmHttpService.sendNotificationToUser(
          userId: adminId,
          title: notification.title,
          body: notification.body,
          channelId: 'admin_notifications',
          data: {
            'type': 'admin_notification',
            'notificationId': notification.id,
            'timestamp': notification.timestamp.toIso8601String(),
            'priority': notification.priority.toString(),
            'type': notification.type,
            'action': 'open_admin_notifications',
          },
        );
      }

      debugPrint('✅ Real FCM notification sent to ${adminUsers.length} admins');
    } catch (e) {
      debugPrint('❌ Error sending real FCM notification: $e');
    }
  }

  /// الحصول على قائمة معرفات المستخدمين الأدمن
  Future<List<String>> _getAdminUsers() async {
    try {
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return usersQuery.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting admin users: $e');
      return [];
    }
  }

  /// إرسال إشعار اختبار حقيقي للأدمن
  Future<void> sendRealTestNotification() async {
    try {
      debugPrint('🧪 Sending real test notification to admins...');

      final fcmHttpService = FCMHttpService();

      // إرسال إشعار اختبار حقيقي للمستخدم الحالي
      final success = await fcmHttpService.sendInstantTestNotification(
        title: '🧪 إشعار اختبار حقيقي للأدمن',
        body: 'هذا إشعار حقيقي يجب أن يظهر في شريط الإشعارات حتى لو كان التطبيق مغلق أو في الخلفية',
        channelId: 'admin_notifications',
        data: {
          'type': 'admin_test',
          'action': 'open_admin_notifications',
          'priority': 'high',
        },
      );

      if (success) {
        debugPrint('✅ Real test notification sent successfully');
      } else {
        debugPrint('❌ Failed to send real test notification');
      }
    } catch (e) {
      debugPrint('❌ Error sending real test notification: $e');
    }
  }

  // Getters للبيانات
  List<AdminNotificationModel> get notifications => List.unmodifiable(_localNotificationsList);
  int get unreadCount => _unreadCount;
  bool get isInitialized => _isInitialized;
  Stream<List<AdminNotificationModel>> get notificationsStream => _notificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// تنظيف الموارد
  void dispose() {
    _notificationsController.close();
    _unreadCountController.close();
  }
}
