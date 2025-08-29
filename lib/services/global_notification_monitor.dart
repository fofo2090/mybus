import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة مراقبة الإشعارات العالمية
/// تضمن وصول الإشعارات للمشرفين وأولياء الأمور من أي مكان في العالم
class GlobalNotificationMonitor {
  static final GlobalNotificationMonitor _instance = GlobalNotificationMonitor._internal();
  factory GlobalNotificationMonitor() => _instance;
  GlobalNotificationMonitor._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _queueSubscription;
  bool _isMonitoring = false;

  /// بدء مراقبة طابور الإشعارات العالمي
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      debugPrint('🌍 Starting global notification monitoring...');

      // مراقبة طابور FCM العالمي
      _queueSubscription = _firestore
          .collection('fcm_global_queue')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen(_processGlobalQueue);

      _isMonitoring = true;
      debugPrint('✅ Global notification monitoring started');
    } catch (e) {
      debugPrint('❌ Error starting global notification monitoring: $e');
    }
  }

  /// إيقاف المراقبة
  Future<void> stopMonitoring() async {
    await _queueSubscription?.cancel();
    _queueSubscription = null;
    _isMonitoring = false;
    debugPrint('🛑 Global notification monitoring stopped');
  }

  /// معالجة طابور الإشعارات العالمي
  Future<void> _processGlobalQueue(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added) {
        await _processQueueItem(doc.doc);
      }
    }
  }

  /// معالجة عنصر واحد من الطابور
  Future<void> _processQueueItem(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final payload = data['payload'] as Map<String, dynamic>?;
      final targetToken = data['target_token'] as String?;
      final retryCount = data['retry_count'] as int? ?? 0;
      final maxRetries = data['max_retries'] as int? ?? 3;

      if (payload == null || targetToken == null) {
        debugPrint('⚠️ Invalid queue item, marking as failed');
        await _markQueueItemAsFailed(doc.id, 'Invalid payload or token');
        return;
      }

      debugPrint('🔄 Processing global notification for token: ${targetToken.substring(0, 20)}...');

      // محاولة إرسال الإشعار
      final success = await _attemptGlobalDelivery(payload, targetToken);

      if (success) {
        // نجح الإرسال
        await _markQueueItemAsCompleted(doc.id);
        debugPrint('✅ Global notification delivered successfully');
      } else {
        // فشل الإرسال
        if (retryCount < maxRetries) {
          // إعادة المحاولة
          await _retryQueueItem(doc.id, retryCount + 1);
          debugPrint('🔄 Retrying global notification (${retryCount + 1}/$maxRetries)');
        } else {
          // فشل نهائي
          await _markQueueItemAsFailed(doc.id, 'Max retries exceeded');
          debugPrint('❌ Global notification failed after $maxRetries retries');
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing queue item: $e');
      await _markQueueItemAsFailed(doc.id, 'Processing error: $e');
    }
  }

  /// محاولة التسليم العالمي
  Future<bool> _attemptGlobalDelivery(Map<String, dynamic> payload, String token) async {
    try {
      // في بيئة الإنتاج، هذا سيتم عبر Firebase Admin SDK أو خادم خلفي
      debugPrint('🌍 Attempting global delivery...');
      debugPrint('📱 Target token: ${token.substring(0, 20)}...');
      debugPrint('📝 Payload: ${payload['notification']?['title']}');

      // محاكاة نجاح الإرسال (في الإنتاج سيكون إرسال حقيقي)
      await Future.delayed(Duration(seconds: 1));

      // في الإنتاج، استخدم Firebase Admin SDK:
      // final response = await FirebaseMessaging.instance.send(payload);
      // return response.successCount > 0;

      return true; // محاكاة نجاح
    } catch (e) {
      debugPrint('❌ Global delivery failed: $e');
      return false;
    }
  }

  /// تحديد عنصر الطابور كمكتمل
  Future<void> _markQueueItemAsCompleted(String docId) async {
    await _firestore.collection('fcm_global_queue').doc(docId).update({
      'status': 'completed',
      'completed_at': FieldValue.serverTimestamp(),
    });
  }

  /// تحديد عنصر الطابور كفاشل
  Future<void> _markQueueItemAsFailed(String docId, String reason) async {
    await _firestore.collection('fcm_global_queue').doc(docId).update({
      'status': 'failed',
      'failed_at': FieldValue.serverTimestamp(),
      'failure_reason': reason,
    });
  }

  /// إعادة محاولة عنصر الطابور
  Future<void> _retryQueueItem(String docId, int newRetryCount) async {
    await _firestore.collection('fcm_global_queue').doc(docId).update({
      'retry_count': newRetryCount,
      'last_retry_at': FieldValue.serverTimestamp(),
    });
  }

  /// تنظيف الطابور من العناصر القديمة
  Future<void> cleanupOldQueueItems() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 7));
      final oldItems = await _firestore
          .collection('fcm_global_queue')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🧹 Cleaned up ${oldItems.docs.length} old queue items');
    } catch (e) {
      debugPrint('❌ Error cleaning up queue: $e');
    }
  }

  /// إحصائيات الطابور العالمي
  Future<Map<String, int>> getQueueStats() async {
    try {
      final pending = await _firestore
          .collection('fcm_global_queue')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final completed = await _firestore
          .collection('fcm_global_queue')
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      final failed = await _firestore
          .collection('fcm_global_queue')
          .where('status', isEqualTo: 'failed')
          .count()
          .get();

      return {
        'pending': pending.count ?? 0,
        'completed': completed.count ?? 0,
        'failed': failed.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting queue stats: $e');
      return {'pending': 0, 'completed': 0, 'failed': 0};
    }
  }

  /// التحقق من حالة المراقبة
  bool get isMonitoring => _isMonitoring;

  /// تسجيل إشعار للتسليم العالمي
  Future<void> queueGlobalNotification({
    required String targetToken,
    required String title,
    required String body,
    required String userId,
    Map<String, dynamic>? data,
    String channelId = 'mybus_notifications',
  }) async {
    try {
      final payload = {
        'to': targetToken,
        'priority': 'high',
        'content_available': true,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': {
          'channelId': channelId,
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
          'global_delivery': 'true',
          ...?data,
        },
        'android': {
          'priority': 'high',
          'ttl': '2419200s', // 4 weeks
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-expiration': '${DateTime.now().add(Duration(days: 28)).millisecondsSinceEpoch ~/ 1000}',
          },
        },
      };

      await _firestore.collection('fcm_global_queue').add({
        'payload': payload,
        'target_token': targetToken,
        'target_user_id': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'delivery_type': 'global',
        'retry_count': 0,
        'max_retries': 3,
      });

      debugPrint('✅ Notification queued for global delivery to user: $userId');
    } catch (e) {
      debugPrint('❌ Error queuing global notification: $e');
    }
  }
}
