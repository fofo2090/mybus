import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/student_model.dart';
import 'enhanced_notification_service.dart';
import 'unified_notification_service.dart';
import 'notification_dialog_service.dart';


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();
  final UnifiedNotificationService _unifiedService = UnifiedNotificationService();

  // Initialize notifications
  Future<void> initialize() async {
    // Skip initialization on web to avoid service worker issues
    if (kIsWeb) {
      debugPrint('Notification service skipped on web platform');
      return;
    }

    // Initialize unified notification service
    await _unifiedService.initialize();

    // Initialize enhanced notification service
    await _enhancedService.initialize();

    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background messages are handled by the global handler in main.dart
      // FirebaseMessaging.onBackgroundMessage can only be called once globally
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Handle foreground messages with sound and system notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Received foreground message: ${message.notification?.title}');
    debugPrint('📋 Message data: ${message.data}');

    // التحقق من المستخدم المستهدف قبل عرض الإشعار
    final targetUserId = message.data['userId'] ?? message.data['recipientId'];
    final currentUser = FirebaseAuth.instance.currentUser;

    debugPrint('🎯 Target user ID: $targetUserId');
    debugPrint('👤 Current user ID: ${currentUser?.uid}');

    // إذا لم يكن هناك targetUserId محدد، اعرض الإشعار لجميع المستخدمين
    if (targetUserId == null || currentUser?.uid == targetUserId) {
      // عرض الإشعار للمستخدم المستهدف أو لجميع المستخدمين إذا لم يكن محدد
      debugPrint('✅ Showing notification for user: ${currentUser?.uid}');
      _showSystemNotification(message, targetUserId);

      // عرض dialog تنبيهي للمستخدم باستخدام الخدمة المحسنة
      NotificationDialogService().showNotificationDialog(message);
    } else {
      debugPrint('⚠️ Notification not for current user (${currentUser?.uid}), target: $targetUserId');
      debugPrint('📤 Notification skipped - not for current user');
    }
  }

  // Show system notification with sound
  void _showSystemNotification(RemoteMessage message, String? targetUserId) {
    try {
      // استخدام الخدمة الموحدة لعرض الإشعار المحلي
      _unifiedService.showLocalNotification(
        title: message.notification?.title ?? 'إشعار جديد',
        body: message.notification?.body ?? '',
        channelId: message.data['channelId'] ?? 'mybus_notifications',
        data: message.data,
        targetUserId: targetUserId,
      );

      debugPrint('🔊 System notification displayed with sound');

      // يمكن إضافة vibration أو sound إضافي هنا إذا لزم الأمر
      // HapticFeedback.vibrate(); // يتطلب import 'package:flutter/services.dart';

    } catch (e) {
      debugPrint('❌ Error showing system notification: $e');
    }
  }

  // Handle background messages with enhanced sound and display
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Received background message with sound: ${message.notification?.title}');

    // حفظ الإشعار في قاعدة البيانات المحلية حتى لو كان التطبيق مغلق
    try {
      final firestore = FirebaseFirestore.instance;

      // إنشاء إشعار من الرسالة المستلمة مع إعدادات الصوت
      final notification = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'إشعار جديد',
        'body': message.notification?.body ?? '',
        'recipientId': message.data['recipientId'] ?? '',
        'type': message.data['type'] ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          ...message.data,
          'sound_played': true,
          'background_received': true,
          'received_at': DateTime.now().toIso8601String(),
        },
        // إعدادات إضافية للصوت والعرض
        'notification_settings': {
          'sound': true,
          'vibration': true,
          'priority': 'high',
          'show_in_foreground': true,
        }
      };

      // حفظ الإشعار في Firestore
      await firestore.collection('notifications').add(notification);

      debugPrint('✅ Background notification with sound saved to database');

      // إضافة log للتتبع
      await firestore.collection('notification_logs').add({
        'message_id': message.messageId,
        'title': message.notification?.title,
        'received_at': FieldValue.serverTimestamp(),
        'type': 'background',
        'sound_enabled': true,
        'platform': 'android',
      });

    } catch (e) {
      debugPrint('❌ Error saving background notification: $e');
    }
  }

  // Send notification for student boarding
  Future<void> sendStudentBoardedNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      if (student.parentId.isEmpty) {
        debugPrint('⚠️ Cannot send notification for ${student.name} because parentId is missing.');
        return;
      }
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'ركب ${student.name} الباص',
        body: 'ركب ${student.name} الباص مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.studentBoarded,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'boarded',
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار ركوب الطالب: $e');
    }
  }

  // Send notification for student leaving
  Future<void> sendStudentLeftNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      if (student.parentId.isEmpty) {
        debugPrint('⚠️ Cannot send notification for ${student.name} because parentId is missing.');
        return;
      }
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'نزل ${student.name} من الباص',
        body: 'نزل ${student.name} من الباص مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.studentLeft,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'left',
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار نزول الطالب: $e');
    }
  }

  // Send general notification
  Future<void> sendGeneralNotification({
    required String title,
    required String body,
    required String recipientId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: data,
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال الإشعار: $e');
    }
  }

  // Send trip started notification
  Future<void> sendTripStartedNotification({
    required String recipientId,
    required String studentName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'بدء الرحلة',
        body: 'تم بدء رحلة الباص. سيتم إشعارك عند ركوب $studentName الباص.',
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'type': 'trip_started',
          'studentName': studentName,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار بدء الرحلة: $e');
    }
  }

  // Send trip ended notification
  Future<void> sendTripEndedNotification({
    required String recipientId,
    required String studentName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'انتهاء الرحلة',
        body: 'تم انتهاء رحلة الباص.',
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'type': 'trip_ended',
          'studentName': studentName,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار انتهاء الرحلة: $e');
    }
  }

  // Send student status update notification
  Future<void> sendStudentStatusUpdateNotification({
    required String recipientId,
    required String studentName,
    required String status,
    required String action,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'تحديث حالة $studentName',
        body: status,
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'type': 'status_update',
          'studentName': studentName,
          'action': action,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تحديث الحالة: $e');
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotification(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  // Send push notification with sound and system notification display
  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // الحصول على FCM token للمستخدم المحدد
      final userDoc = await _firestore.collection('users').doc(notification.recipientId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // حفظ الإشعار في قاعدة البيانات + إرسال FCM للوصول العالمي
        await _firestore.collection('fcm_queue').add({
          'recipientId': notification.recipientId,
          'fcmToken': fcmToken, // إضافة FCM token للمستخدم المحدد
          'title': notification.title,
          'body': notification.body,
        'data': {
          ...notification.data ?? {},
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'sound': 'default',
          'priority': 'high',
          'notification_priority': 'PRIORITY_MAX',
          'importance': 'high',
          'channel_id': 'mybus_notifications',
          'userId': notification.recipientId, // تأكيد المستخدم المستهدف
          'recipientId': notification.recipientId, // إضافة recipientId أيضاً
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': notification.type.toString().split('.').last,
        'global_delivery': true, // تمكين التسليم العالمي
        'retry_count': 0,
        'max_retries': 3,
        // إعدادات Android محسنة للصوت والعرض والوصول العالمي
        'android': {
          'priority': 'high',
          'ttl': '2419200s', // 4 weeks للوصول العالمي
          'notification': {
            'title': notification.title,
            'body': notification.body,
            'channel_id': 'mybus_notifications',
            'priority': 'high',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'public',
            'show_when': true,
            'local_only': false, // مهم للوصول العالمي
            'sticky': false,
            'icon': 'ic_notification',
            'color': '#FF6B6B',
            'tag': 'mybus_${notification.type.toString().split('.').last}',
          }
        },
        // إعدادات iOS محسنة للوصول العالمي
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': notification.title,
                'body': notification.body,
              },
              'badge': 1,
              'sound': 'default',
              'content-available': 1,
              'mutable-content': 1,
              'category': 'MYBUS_NOTIFICATION',
            }
          },
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
            'apns-expiration': '${DateTime.now().add(Duration(days: 28)).millisecondsSinceEpoch ~/ 1000}', // انتهاء بعد 4 أسابيع
          }
        },
        // إعدادات الويب
        'webpush': {
          'headers': {
            'Urgency': 'high',
          },
          'notification': {
            'title': notification.title,
            'body': notification.body,
            'icon': '/icons/notification-icon.png',
            'badge': '/icons/badge-icon.png',
            'sound': '/sounds/notification.mp3',
            'vibrate': [200, 100, 200],
            'requireInteraction': true,
          }
        },
      });

        debugPrint('✅ Enhanced push notification with sound queued for user: ${notification.recipientId}');
      } else {
        debugPrint('⚠️ No FCM token found for user: ${notification.recipientId}, notification will not be sent');
      }
    } catch (e) {
      debugPrint('❌ Error queuing push notification: $e');
    }
  }

  // Get notifications for user
  Stream<List<NotificationModel>> getNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirement
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Limit to 50 notifications
          return notifications.take(50).toList();
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الإشعار: $e');
    }
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['isRead'] == false)
            .length);
  }

  // Delete test notifications
  Future<void> deleteTestNotifications(String userId) async {
    try {
      debugPrint('🧹 Cleaning up test notifications for user: $userId');

      final batch = _firestore.batch();
      final testNotifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .get();

      int deletedCount = 0;
      for (var doc in testNotifications.docs) {
        final data = doc.data();

        // Check if it's a test notification
        final isTestNotification =
            data['title']?.toString().contains('تجريبي') == true ||
            data['body']?.toString().contains('تجريبي') == true ||
            data['data']?['source'] == 'test' ||
            data['type'] == 'general' && data['title'] == 'إشعار تجريبي';

        if (isTestNotification) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('✅ Deleted $deletedCount test notifications');
      } else {
        debugPrint('ℹ️ No test notifications found to delete');
      }
    } catch (e) {
      debugPrint('❌ Error deleting test notifications: $e');
      throw Exception('خطأ في حذف الإشعارات التجريبية: $e');
    }
  }

  // Delete all test notifications from the system
  Future<void> deleteAllTestNotifications() async {
    try {
      debugPrint('🧹 Cleaning up all test notifications from system');

      final batch = _firestore.batch();
      final testNotifications = await _firestore
          .collection('notifications')
          .get();

      int deletedCount = 0;
      for (var doc in testNotifications.docs) {
        final data = doc.data();

        // Check if it's a test notification
        final isTestNotification =
            data['title']?.toString().contains('تجريبي') == true ||
            data['body']?.toString().contains('تجريبي') == true ||
            data['data']?['source'] == 'test' ||
            data['type'] == 'general' && data['title'] == 'إشعار تجريبي';

        if (isTestNotification) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('✅ Deleted $deletedCount test notifications from system');
      } else {
        debugPrint('ℹ️ No test notifications found in system');
      }
    } catch (e) {
      debugPrint('❌ Error deleting all test notifications: $e');
      throw Exception('خطأ في حذف جميع الإشعارات التجريبية: $e');
    }
  }

  // Format time for notification
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }



  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // Send notification when student arrives at school
  Future<void> sendStudentArrivedAtSchoolNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'وصل ${student.name} إلى المدرسة',
        body: 'وصل ${student.name} إلى المدرسة بأمان مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'arrived_at_school',
          'timestamp': timestamp.toIso8601String(),
          'location': 'school',
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار وصول الطالب للمدرسة: $e');
    }
  }

  // ==================== إشعارات شاملة لجميع الأحداث ====================

  // ملاحظة: تم استبدال هذه الدالة بـ notifyStudentAssignmentWithSound
  // التي تستخدم EnhancedNotificationService للحصول على إشعارات محسنة مع الصوت

  // إشعار بدء الرحلة
  Future<void> sendTripStartNotification({
    required String supervisorId,
    required String supervisorName,
    required String busPlateNumber,
    required String direction,
    required List<String> studentIds,
  }) async {
    try {
      // إشعار لأولياء الأمور
      for (String studentId in studentIds) {
        final student = await _getStudentById(studentId);
        if (student != null) {
          final parentNotification = NotificationModel(
            id: _uuid.v4(),
            title: 'بدء رحلة الباص',
            body: 'بدأت رحلة الباص رقم $busPlateNumber ${direction == 'toSchool' ? 'إلى المدرسة' : 'إلى المنزل'} مع المشرف $supervisorName',
            recipientId: student.parentId,
            studentId: studentId,
            studentName: student.name,
            type: NotificationType.general,
            timestamp: DateTime.now(),
            data: {
              'type': 'trip_started',
              'direction': direction,
              'busPlateNumber': busPlateNumber,
              'supervisorName': supervisorName,
            },
          );

          await _saveNotification(parentNotification);
          await _sendPushNotification(parentNotification);
        }
      }

      // إشعار للإدمن (بدون إرسال للمشرف الذي بدأ الرحلة)
      await _sendAdminNotification(
        title: 'بدء رحلة جديدة',
        body: 'بدأ المشرف $supervisorName رحلة الباص $busPlateNumber ${direction == 'toSchool' ? 'إلى المدرسة' : 'إلى المنزل'}',
        excludeAdminId: supervisorId, // استبعاد المشرف إذا كان إدمن أيضاً
        data: {
          'type': 'trip_started',
          'supervisorId': supervisorId,
          'busPlateNumber': busPlateNumber,
          'direction': direction,
          'studentsCount': studentIds.length.toString(),
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار بدء الرحلة: $e');
    }
  }

  // إشعار انتهاء الرحلة
  Future<void> sendTripEndNotification({
    required String supervisorId,
    required String supervisorName,
    required String busPlateNumber,
    required String direction,
    required List<String> studentIds,
  }) async {
    try {
      // إشعار لأولياء الأمور
      for (String studentId in studentIds) {
        final student = await _getStudentById(studentId);
        if (student != null) {
          final parentNotification = NotificationModel(
            id: _uuid.v4(),
            title: 'انتهاء رحلة الباص',
            body: 'انتهت رحلة الباص رقم $busPlateNumber ${direction == 'toSchool' ? 'ووصل إلى المدرسة' : 'ووصل إلى المنطقة'}',
            recipientId: student.parentId,
            studentId: studentId,
            studentName: student.name,
            type: NotificationType.general,
            timestamp: DateTime.now(),
            data: {
              'type': 'trip_ended',
              'direction': direction,
              'busPlateNumber': busPlateNumber,
              'supervisorName': supervisorName,
            },
          );

          await _saveNotification(parentNotification);
          await _sendPushNotification(parentNotification);
        }
      }

      // إشعار للإدمن (بدون إرسال للمشرف الذي أنهى الرحلة)
      await _sendAdminNotification(
        title: 'انتهاء رحلة',
        body: 'انتهى المشرف $supervisorName من رحلة الباص $busPlateNumber ${direction == 'toSchool' ? 'إلى المدرسة' : 'إلى المنزل'}',
        excludeAdminId: supervisorId, // استبعاد المشرف إذا كان إدمن أيضاً
        data: {
          'type': 'trip_ended',
          'supervisorId': supervisorId,
          'busPlateNumber': busPlateNumber,
          'direction': direction,
          'studentsCount': studentIds.length.toString(),
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار انتهاء الرحلة: $e');
    }
  }

  // إشعار تغيير حالة الطالب (في الطريق، وصل، إلخ)
  Future<void> sendStudentStatusChangeNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required String oldStatus,
    required String newStatus,
    required String supervisorName,
  }) async {
    try {
      String statusMessage = _getStatusMessage(newStatus);

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'تحديث حالة ${studentName}',
        body: '$statusMessage مع المشرف $supervisorName',
        recipientId: parentId,
        studentId: studentId,
        studentName: studentName,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'status_change',
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'supervisorName': supervisorName,
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);

      // إشعار للإدمن عن تغيير الحالة
      await _sendAdminNotification(
        title: 'تحديث حالة طالب',
        body: 'تم تحديث حالة $studentName من $oldStatus إلى $newStatus بواسطة $supervisorName',
        data: {
          'type': 'student_status_updated',
          'studentId': studentId,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'supervisorName': supervisorName,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تغيير حالة الطالب: $e');
    }
  }

  // إشعار تسكين مشرف في باص
  Future<void> sendSupervisorAssignmentNotification({
    required String supervisorId,
    required String supervisorName,
    required String busId,
    required String busPlateNumber,
    required String adminName,
    String? adminId, // إضافة معرف الإدمن لاستبعاده
  }) async {
    try {
      // إشعار للمشرف
      final supervisorNotification = NotificationModel(
        id: _uuid.v4(),
        title: 'تم تسكينك في باص جديد',
        body: 'تم تسكينك في الباص رقم $busPlateNumber بواسطة $adminName',
        recipientId: supervisorId,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'supervisor_assignment',
          'busId': busId,
          'busPlateNumber': busPlateNumber,
          'assignedBy': adminName,
        },
      );

      await _saveNotification(supervisorNotification);
      await _sendPushNotification(supervisorNotification);

      // إشعار للإدمن (باستثناء الإدمن الذي قام بالعملية)
      await _sendAdminNotification(
        title: 'تم تسكين مشرف',
        body: 'تم تسكين المشرف $supervisorName في الباص $busPlateNumber',
        excludeAdminId: adminId, // استبعاد الإدمن الذي قام بالعملية
        data: {
          'type': 'supervisor_assignment_completed',
          'supervisorId': supervisorId,
          'busId': busId,
          'assignedBy': adminName,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تسكين المشرف: $e');
    }
  }

  // إشعار غياب طالب
  Future<void> sendStudentAbsenceNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required String reason,
    required DateTime date,
    required String status,
  }) async {
    try {
      String title = status == 'approved' ? 'تم قبول طلب الغياب' :
                    status == 'rejected' ? 'تم رفض طلب الغياب' : 'طلب غياب جديد';

      String body = status == 'approved' ? 'تم قبول طلب غياب $studentName ليوم ${_formatDate(date)}' :
                   status == 'rejected' ? 'تم رفض طلب غياب $studentName ليوم ${_formatDate(date)}' :
                   'تم تسجيل طلب غياب $studentName ليوم ${_formatDate(date)} - السبب: $reason';

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: parentId,
        studentId: studentId,
        studentName: studentName,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'absence_notification',
          'status': status,
          'reason': reason,
          'date': date.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);

      // إشعار للإدمن عن طلب الغياب (بدون إرسال لولي الأمر)
      if (status == 'pending') {
        await _sendAdminNotification(
          title: 'طلب غياب جديد',
          body: 'طلب غياب جديد للطالب $studentName ليوم ${_formatDate(date)} - السبب: $reason',
          excludeAdminId: parentId, // استبعاد ولي الأمر إذا كان إدمن أيضاً
          data: {
            'type': 'new_absence_request',
            'studentId': studentId,
            'studentName': studentName,
            'reason': reason,
            'date': date.toIso8601String(),
          },
        );
      }

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار الغياب: $e');
    }
  }

  // إشعار شكوى جديدة
  Future<void> sendComplaintNotification({
    required String complaintId,
    required String title,
    required String description,
    required String parentId,
    required String parentName,
    required String status,
  }) async {
    try {
      // إشعار لولي الأمر
      if (status != 'pending') {
        String statusText = status == 'resolved' ? 'تم حل الشكوى' :
                           status == 'in_progress' ? 'جاري معالجة الشكوى' : 'تم رفض الشكوى';

        final parentNotification = NotificationModel(
          id: _uuid.v4(),
          title: statusText,
          body: 'تم تحديث حالة شكواك: $title',
          recipientId: parentId,
          type: NotificationType.general,
          timestamp: DateTime.now(),
          data: {
            'type': 'complaint_status_update',
            'complaintId': complaintId,
            'status': status,
          },
        );

        await _saveNotification(parentNotification);
        await _sendPushNotification(parentNotification);
      }

      // إشعار للإدمن (بدون إرسال لولي الأمر)
      await _sendAdminNotification(
        title: status == 'pending' ? 'شكوى جديدة' : 'تحديث حالة شكوى',
        body: status == 'pending' ? 'شكوى جديدة من $parentName: $title' : 'تم تحديث حالة الشكوى: $title',
        excludeAdminId: parentId, // استبعاد ولي الأمر إذا كان إدمن أيضاً
        data: {
          'type': status == 'pending' ? 'new_complaint' : 'complaint_updated',
          'complaintId': complaintId,
          'parentName': parentName,
          'status': status,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار الشكوى: $e');
    }
  }

  // إشعار تحديث معلومات الطالب - تم إيقافه لتجنب إرسال إشعارات للأدمن
  @Deprecated('Use EnhancedNotificationService instead - this sends unwanted admin notifications')
  Future<void> sendStudentInfoUpdateNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required List<String> changes,
  }) async {
    debugPrint('⚠️ DEPRECATED: sendStudentInfoUpdateNotification called - use EnhancedNotificationService instead');
    // لا نفعل شيء هنا لتجنب إرسال إشعارات للأدمن
    return;
  }

  // ==================== دوال مساعدة للإشعارات ====================

  // إرسال إشعار للمشرف المحدد فقط
  Future<void> _sendSupervisorNotification({
    required String title,
    required String body,
    required String supervisorId, // مطلوب الآن
    Map<String, dynamic>? data,
  }) async {
    try {
      if (supervisorId.isEmpty) {
        debugPrint('⚠️ Supervisor ID is empty, skipping notification');
        return;
      }

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: supervisorId,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: data,
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
      debugPrint('✅ Notification sent to supervisor: $supervisorId');
    } catch (e) {
      debugPrint('❌ Error sending supervisor notification: $e');
    }
  }

  // إرسال إشعار للإدمن (مع استبعاد إدمن محدد)
  Future<void> _sendAdminNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? excludeAdminId, // استبعاد إدمن محدد
  }) async {
    try {
      final admins = await _getAllAdmins();
      for (var admin in admins) {
        // تخطي الإدمن المستبعد
        if (excludeAdminId != null && admin['id'] == excludeAdminId) {
          continue;
        }

        final notification = NotificationModel(
          id: _uuid.v4(),
          title: title,
          body: body,
          recipientId: admin['id'],
          type: NotificationType.general,
          timestamp: DateTime.now(),
          data: data,
        );

        await _saveNotification(notification);
        await _sendPushNotification(notification);
      }
    } catch (e) {
      debugPrint('❌ Error sending admin notification: $e');
    }
  }

  // الحصول على جميع المشرفين
  Future<List<Map<String, dynamic>>> _getAllSupervisors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'supervisor') // تصحيح الحقل
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting supervisors: $e');
      return [];
    }
  }

  // الحصول على جميع الإدمن
  Future<List<Map<String, dynamic>>> _getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin') // تصحيح الحقل
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting admins: $e');
      return [];
    }
  }

  // الحصول على بيانات طالب
  Future<StudentModel?> _getStudentById(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting student: $e');
      return null;
    }
  }

  // تحويل حالة الطالب إلى رسالة
  String _getStatusMessage(String status) {
    switch (status) {
      case 'onBus':
        return 'ركب ${status} الباص';
      case 'atSchool':
        return 'وصل إلى المدرسة';
      case 'leftSchool':
        return 'غادر المدرسة';
      case 'onWayHome':
        return 'في الطريق إلى المنزل';
      case 'arrivedHome':
        return 'وصل إلى المنزل';
      case 'absent':
        return 'غائب اليوم';
      default:
        return 'تم تحديث الحالة';
    }
  }

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Send notification when student arrives at home
  Future<void> sendStudentArrivedAtHomeNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'وصل ${student.name} إلى المنزل',
        body: 'وصل ${student.name} إلى المنزل بأمان مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'arrived_at_home',
          'timestamp': timestamp.toIso8601String(),
          'location': 'home',
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار وصول الطالب للمنزل: $e');
    }
  }

  // Send notification when student is on bus
  Future<void> sendStudentOnBusNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
    required String busRoute,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: '${student.name} في الباص',
        body: '${student.name} الآن في الباص (خط $busRoute) مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'on_bus',
          'timestamp': timestamp.toIso8601String(),
          'location': 'bus',
          'busRoute': busRoute,
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار وجود الطالب في الباص: $e');
    }
  }

  // ==================== إشعارات محسنة مع الصوت ====================

  /// إشعار تسكين الطالب مع الصوت
  Future<void> notifyStudentAssignmentWithSound({
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
    await _enhancedService.notifyStudentAssignment(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      busRoute: busRoute,
      parentId: parentId,
      supervisorId: supervisorId,
      parentName: parentName,
      parentPhone: parentPhone,
      excludeAdminId: excludeAdminId,
    );
  }

  /// إشعار إلغاء تسكين الطالب مع الصوت
  Future<void> notifyStudentUnassignmentWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
    String? excludeAdminId, // استبعاد إدمن محدد من الإشعارات
  }) async {
    await _enhancedService.notifyStudentUnassignment(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      parentId: parentId,
      supervisorId: supervisorId,
      excludeAdminId: excludeAdminId,
    );
  }

  /// إشعار ركوب الطالب مع الصوت
  Future<void> notifyStudentBoardedWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyStudentBoarded(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      parentId: parentId,
      supervisorId: supervisorId,
      timestamp: DateTime.now(),
    );
  }

  /// إشعار نزول الطالب مع الصوت
  Future<void> notifyStudentAlightedWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyStudentAlighted(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      parentId: parentId,
      supervisorId: supervisorId,
      timestamp: DateTime.now(),
    );
  }

  /// إشعار طلب غياب مع الصوت
  Future<void> notifyAbsenceRequestWithSound({
    required String studentId,
    required String studentName,
    required String parentId,
    required String parentName,
    required String supervisorId,
    required String busId,
    required DateTime absenceDate,
    required String reason,
  }) async {
    await _enhancedService.notifyAbsenceRequest(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      parentName: parentName,
      supervisorId: supervisorId,
      busId: busId,
      absenceDate: absenceDate,
      reason: reason,
    );
  }

  /// إشعار الموافقة على الغياب مع الصوت
  Future<void> notifyAbsenceApprovedWithSound({
    required String studentId,
    required String studentName,
    required String parentId,
    required String supervisorId,
    required DateTime absenceDate,
    required String approvedBy,
    String? approvedBySupervisorId, // معرف المشرف الذي وافق لاستبعاده
  }) async {
    await _enhancedService.notifyAbsenceApproved(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      supervisorId: supervisorId,
      absenceDate: absenceDate,
      approvedBy: approvedBy,
      approvedBySupervisorId: approvedBySupervisorId,
    );
  }

  /// إشعار رفض الغياب مع الصوت
  Future<void> notifyAbsenceRejectedWithSound({
    required String studentId,
    required String studentName,
    required String parentId,
    required String supervisorId,
    required DateTime absenceDate,
    required String rejectedBy,
    required String reason,
    String? rejectedBySupervisorId, // معرف المشرف الذي رفض لاستبعاده
  }) async {
    await _enhancedService.notifyAbsenceRejected(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      supervisorId: supervisorId,
      absenceDate: absenceDate,
      rejectedBy: rejectedBy,
      reason: reason,
      rejectedBySupervisorId: rejectedBySupervisorId,
    );
  }

  /// إشعار شكوى جديدة مع الصوت
  Future<void> notifyNewComplaintWithSound({
    required String complaintId,
    required String parentId,
    required String parentName,
    required String subject,
    required String category,
  }) async {
    await _enhancedService.notifyNewComplaint(
      complaintId: complaintId,
      parentId: parentId,
      parentName: parentName,
      subject: subject,
      category: category,
    );
  }

  /// إشعار رد على الشكوى مع الصوت
  Future<void> notifyComplaintResponseWithSound({
    required String complaintId,
    required String parentId,
    required String subject,
    required String response,
  }) async {
    await _enhancedService.notifyComplaintResponse(
      complaintId: complaintId,
      parentId: parentId,
      subject: subject,
      response: response,
    );
  }

  /// إشعار تقييم المشرف مع الصوت
  Future<void> notifySupervisorEvaluationWithSound({
    required String supervisorId,
    required String supervisorName,
    required String parentId,
    required String parentName,
    required String studentName,
    required double averageRating,
    String? comments,
  }) async {
    await _enhancedService.notifySupervisorEvaluation(
      supervisorId: supervisorId,
      supervisorName: supervisorName,
      parentId: parentId,
      parentName: parentName,
      studentName: studentName,
      averageRating: averageRating,
      comments: comments,
    );
  }

  /// إشعار تسجيل ولي أمر جديد مع الصوت
  Future<void> notifyNewParentRegistrationWithSound({
    required String parentId,
    required String parentName,
    required String parentEmail,
    required String parentPhone,
    required DateTime registrationDate,
  }) async {
    await _enhancedService.notifyNewParentRegistration(
      parentId: parentId,
      parentName: parentName,
      parentEmail: parentEmail,
      parentPhone: parentPhone,
      registrationDate: registrationDate,
    );
  }

  /// إشعار استبيان جديد مع الصوت
  Future<void> notifyNewSurveyWithSound({
    required String surveyId,
    required String surveyTitle,
    required String surveyDescription,
    required String createdBy,
    required DateTime deadline,
    required List<String> targetUserIds,
  }) async {
    await _enhancedService.notifyNewSurvey(
      surveyId: surveyId,
      surveyTitle: surveyTitle,
      surveyDescription: surveyDescription,
      createdBy: createdBy,
      deadline: deadline,
      targetUserIds: targetUserIds,
    );
  }

  /// إشعار تذكير انتهاء موعد الاستبيان مع الصوت
  Future<void> notifySurveyDeadlineReminderWithSound({
    required String surveyId,
    required String surveyTitle,
    required DateTime deadline,
    required List<String> pendingUserIds,
  }) async {
    await _enhancedService.notifySurveyDeadlineReminder(
      surveyId: surveyId,
      surveyTitle: surveyTitle,
      deadline: deadline,
      pendingUserIds: pendingUserIds,
    );
  }

  /// إشعار تعيين مشرف جديد مع الصوت
  Future<void> notifyNewSupervisorAssignmentWithSound({
    required String supervisorId,
    required String supervisorName,
    required String busId,
    required String busRoute,
    required String assignedBy,
  }) async {
    await _enhancedService.notifyNewSupervisorAssignment(
      supervisorId: supervisorId,
      supervisorName: supervisorName,
      busId: busId,
      busRoute: busRoute,
      assignedBy: assignedBy,
    );
  }

  /// إشعار تحديث جدول الرحلات مع الصوت
  Future<void> notifyScheduleUpdateWithSound({
    required String busId,
    required String busRoute,
    required String supervisorId,
    required List<String> parentIds,
    required String updatedBy,
    required Map<String, dynamic> scheduleChanges,
  }) async {
    await _enhancedService.notifyScheduleUpdate(
      busId: busId,
      busRoute: busRoute,
      supervisorId: supervisorId,
      parentIds: parentIds,
      updatedBy: updatedBy,
      scheduleChanges: scheduleChanges,
    );
  }

  /// إشعار تحديث حالة الرحلة مع الصوت
  Future<void> notifyTripStatusUpdateWithSound({
    required String busId,
    required String busRoute,
    required String status,
    required List<String> parentIds,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyTripStatusUpdate(
      busId: busId,
      busRoute: busRoute,
      status: status,
      parentIds: parentIds,
      supervisorId: supervisorId,
    );
  }

  /// إشعار طوارئ مع الصوت
  Future<void> notifyEmergencyWithSound({
    required String busId,
    required String supervisorId,
    required String supervisorName,
    required String emergencyType,
    required String description,
    required List<String> parentIds,
  }) async {
    await _enhancedService.notifyEmergency(
      busId: busId,
      supervisorId: supervisorId,
      supervisorName: supervisorName,
      emergencyType: emergencyType,
      description: description,
      parentIds: parentIds,
    );
  }

  /// حفظ FCM token للمستخدم
  Future<void> saveFCMTokenForUser(String userId) async {
    await _enhancedService.saveFCMToken(userId);
  }

  /// الحصول على الإشعارات غير المقروءة
  Stream<List<NotificationModel>> getUnreadNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// تحديد الإشعار كمقروء (دالة محسنة)
  Future<void> markNotificationAsReadEnhanced(String notificationId) async {
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
  Future<void> deleteNotificationById(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  /// إشعار ترحيبي لولي الأمر الجديد
  Future<void> sendWelcomeNotificationToNewParent({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      debugPrint('🎉 Sending welcome notification to new parent: $parentName');

      // استخدام الخدمة المحسنة للإشعار الترحيبي
      await _enhancedService.sendWelcomeNotificationToNewParent(
        parentId: parentId,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
      );

      // إشعار للإدمن عن التسجيل الجديد
      await _sendAdminNotification(
        title: '👨‍👩‍👧‍👦 تسجيل ولي أمر جديد',
        body: 'تم تسجيل ولي أمر جديد: $parentName\nالبريد الإلكتروني: $parentEmail${parentPhone != null ? '\nرقم الهاتف: $parentPhone' : ''}',
        data: {
          'type': 'new_parent_registration',
          'parentId': parentId,
          'parentName': parentName,
          'parentEmail': parentEmail,
          'parentPhone': parentPhone ?? '',
          'registrationDate': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Welcome notification sent successfully to: $parentName');
    } catch (e) {
      debugPrint('❌ Error sending welcome notification: $e');
      throw Exception('خطأ في إرسال إشعار الترحيب: $e');
    }
  }

  /// إشعار ترحيبي سريع لولي الأمر الجديد
  Future<void> sendQuickWelcomeNotification({
    required String parentId,
    required String parentName,
  }) async {
    try {
      debugPrint('🎉 Sending quick welcome notification to: $parentName');

      // استخدام الخدمة المحسنة للإشعار السريع
      await _enhancedService.sendQuickWelcomeNotification(
        parentId: parentId,
        parentName: parentName,
      );

      debugPrint('✅ Quick welcome notification sent to: $parentName');
    } catch (e) {
      debugPrint('❌ Error sending quick welcome notification: $e');
      throw Exception('خطأ في إرسال الإشعار الترحيبي السريع: $e');
    }
  }




}
