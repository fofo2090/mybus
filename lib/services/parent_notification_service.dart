import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parent_notification_model.dart';
import '../widgets/parent_notification_dialog.dart';
import '../models/parent_notification_model.dart';

/// خدمة الإشعارات المتقدمة لولي الأمر
/// تعرض dialog جميل ثم تحفظ في قائمة الإشعارات المحلية
class ParentNotificationService {
  static final ParentNotificationService _instance = ParentNotificationService._internal();
  factory ParentNotificationService() => _instance;
  ParentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // مفتاح حفظ الإشعارات المحلية
  static const String _notificationsKey = 'parent_local_notifications';
  static const String _unreadCountKey = 'parent_unread_count';

  // Context للعرض
  BuildContext? _context;

  // قائمة الإشعارات المحلية
  List<ParentNotificationModel> _localNotificationsList = [];
  
  // عداد الإشعارات غير المقروءة
  int _unreadCount = 0;
  
  // Stream controller للإشعارات
  final StreamController<List<ParentNotificationModel>> _notificationsController = 
      StreamController<List<ParentNotificationModel>>.broadcast();
  
  final StreamController<int> _unreadCountController = 
      StreamController<int>.broadcast();

  /// تهيئة الخدمة
  Future<void> initialize(BuildContext context) async {
    _context = context;
    
    try {
      debugPrint('🔔 تهيئة خدمة إشعارات ولي الأمر...');
      
      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();
      
      // تحميل الإشعارات المحفوظة
      await _loadSavedNotifications();
      
      // إعداد معالجات الرسائل
      _setupMessageHandlers();
      
      debugPrint('✅ تم تهيئة خدمة إشعارات ولي الأمر بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة إشعارات ولي الأمر: $e');
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
      'parent_notifications',
      'إشعارات ولي الأمر',
      description: 'إشعارات خاصة بولي الأمر',
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
    debugPrint('📱 إشعار جديد لولي الأمر (التطبيق نشط): ${message.notification?.title}');
    
    // التحقق من أن المستخدم الحالي هو ولي أمر
    if (!_isCurrentUserParent()) return;
    
    // التحقق من أن الإشعار مخصص لهذا المستخدم
    if (!_isNotificationForCurrentUser(message)) return;
    
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
    debugPrint('📱 إشعار جديد لولي الأمر (من الخلفية): ${message.notification?.title}');
    
    if (!_isCurrentUserParent()) return;
    if (!_isNotificationForCurrentUser(message)) return;
    
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

  /// التحقق من أن المستخدم الحالي ولي أمر
  bool _isCurrentUserParent() {
    final user = FirebaseAuth.instance.currentUser;
    // يمكن إضافة منطق أكثر تعقيداً للتحقق من نوع المستخدم
    return user != null;
  }

  /// التحقق من أن الإشعار مخصص للمستخدم الحالي
  bool _isNotificationForCurrentUser(RemoteMessage message) {
    final targetUserId = message.data['userId'] ?? message.data['recipientId'];
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // إذا لم يكن هناك مستخدم مستهدف محدد، فالإشعار عام
    if (targetUserId == null) return true;
    
    return currentUser?.uid == targetUserId;
  }

  /// إنشاء نموذج الإشعار من RemoteMessage
  ParentNotificationModel _createNotificationModel(RemoteMessage message) {
    return ParentNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'general',
      priority: _getPriorityFromData(message.data),
      studentId: message.data['studentId'],
      busId: message.data['busId'],
    );
  }

  /// تحديد أولوية الإشعار
  ParentNotificationPriority _getPriorityFromData(Map<String, dynamic> data) {
    final priority = data['priority']?.toString().toLowerCase();
    switch (priority) {
      case 'high':
        return ParentNotificationPriority.high;
      case 'urgent':
        return ParentNotificationPriority.urgent;
      case 'low':
        return ParentNotificationPriority.low;
      default:
        return ParentNotificationPriority.normal;
    }
  }

  /// عرض Dialog جميل للإشعار
  Future<void> _showNotificationDialog(ParentNotificationModel notification) async {
    if (_context == null) return;

    // اهتزاز خفيف
    HapticFeedback.lightImpact();

    return showDialog(
      context: _context!,
      barrierDismissible: true,
      builder: (context) => ParentNotificationDialog(
        notification: notification,
        onDismiss: () => Navigator.of(context).pop(),
        onMarkAsRead: () => markAsRead(notification.id),
      ),
    );
  }

  /// حفظ الإشعار محلياً
  Future<void> _saveNotificationLocally(ParentNotificationModel notification) async {
    try {
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

  /// عرض إشعار في شريط الإشعارات
  Future<void> _showLocalNotification(ParentNotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      'parent_notifications',
      'إشعارات ولي الأمر',
      channelDescription: 'إشعارات خاصة بولي الأمر',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      showWhen: true,
      when: null,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toMap()),
    );
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notification = ParentNotificationModel.fromMap(data);
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
          .map((json) => ParentNotificationModel.fromMap(jsonDecode(json)))
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

  // Getters للبيانات
  List<ParentNotificationModel> get notifications => List.unmodifiable(_localNotificationsList);
  int get unreadCount => _unreadCount;
  Stream<List<ParentNotificationModel>> get notificationsStream => _notificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// تنظيف الموارد
  void dispose() {
    _notificationsController.close();
    _unreadCountController.close();
  }
}
