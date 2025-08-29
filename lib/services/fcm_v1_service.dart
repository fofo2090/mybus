import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة إرسال إشعارات FCM باستخدام HTTP v1 API
/// تدعم الإرسال للأجهزة المختلفة مع تحسينات خاصة لكل منصة
class FCMv1Service {
  static const String _projectId = 'mybus-5a992';
  static const String _fcmUrl = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final FCMv1Service _instance = FCMv1Service._internal();
  factory FCMv1Service() => _instance;
  FCMv1Service._internal();

  /// إرسال إشعار Alert Notification (يظهر في notification tray)
  Future<bool> sendAlertNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      debugPrint('📤 Sending alert notification to: ${deviceToken.substring(0, 20)}...');
      
      final payload = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": title,
            "body": body,
            if (imageUrl != null) "image": imageUrl,
          },
          "data": {
            "type": "alert",
            "timestamp": DateTime.now().toIso8601String(),
            ...?data,
          },
          "android": {
            "priority": "HIGH",
            "notification": {
              "channel_id": "mybus_notifications",
              "sound": "default",
              "icon": "ic_notification",
              "color": "#1E88E5",
              "default_sound": true,
              "default_vibrate_timings": true,
              "default_light_settings": true,
              "notification_priority": "PRIORITY_MAX",
              "visibility": "PUBLIC",
              "sticky": false,
              "local_only": false,
            }
          },
          "apns": {
            "headers": {
              "apns-priority": "10"
            },
            "payload": {
              "aps": {
                "alert": {
                  "title": title,
                  "body": body,
                },
                "sound": "default",
                "badge": 1,
                "content-available": 1,
                "mutable-content": 1,
              }
            }
          },
          "webpush": {
            "headers": {
              "Urgency": "high"
            },
            "notification": {
              "title": title,
              "body": body,
              "icon": "/icons/icon-192x192.png",
              "badge": "/icons/badge-72x72.png",
              "vibrate": [200, 100, 200],
              "requireInteraction": true,
            }
          }
        }
      };

      final success = await _sendHttpRequest(payload);
      
      if (success) {
        // حفظ الإشعار في قاعدة البيانات
        await _saveNotificationToFirestore(
          deviceToken: deviceToken,
          title: title,
          body: body,
          type: 'alert',
          data: data,
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error sending alert notification: $e');
      return false;
    }
  }

  /// إرسال إشعار Data-only (للتحديثات الصامتة)
  Future<bool> sendDataOnlyNotification({
    required String deviceToken,
    required Map<String, String> data,
  }) async {
    try {
      debugPrint('📤 Sending data-only notification to: ${deviceToken.substring(0, 20)}...');
      
      final payload = {
        "message": {
          "token": deviceToken,
          "data": {
            "type": "silentUpdate",
            "timestamp": DateTime.now().toIso8601String(),
            ...data,
          },
          "android": {
            "priority": "HIGH",
          },
          "apns": {
            "headers": {
              "apns-priority": "5"
            },
            "payload": {
              "aps": {
                "content-available": 1
              }
            }
          }
        }
      };

      return await _sendHttpRequest(payload);
    } catch (e) {
      debugPrint('❌ Error sending data-only notification: $e');
      return false;
    }
  }

  /// إرسال إشعار لمجموعة من الأجهزة
  Future<Map<String, bool>> sendBatchNotifications({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    final results = <String, bool>{};
    
    // إرسال متوازي للإشعارات (بحد أقصى 10 في نفس الوقت)
    final futures = <Future<void>>[];
    
    for (int i = 0; i < deviceTokens.length; i += 10) {
      final batch = deviceTokens.skip(i).take(10).toList();
      
      for (final token in batch) {
        futures.add(
          sendAlertNotification(
            deviceToken: token,
            title: title,
            body: body,
            data: data,
            imageUrl: imageUrl,
          ).then((success) {
            results[token] = success;
          }).catchError((error) {
            debugPrint('❌ Error sending to $token: $error');
            results[token] = false;
          })
        );
      }
      
      // انتظار انتهاء الدفعة الحالية قبل البدء في التالية
      await Future.wait(futures);
      futures.clear();
      
      // توقف قصير لتجنب rate limiting
      if (i + 10 < deviceTokens.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return results;
  }

  /// إرسال طلب HTTP إلى FCM
  Future<bool> _sendHttpRequest(Map<String, dynamic> payload) async {
    try {
      // في بيئة الإنتاج، يجب الحصول على access token من service account
      // هنا نستخدم مثال للتوضيح
      final accessToken = await _getAccessToken();
      
      if (accessToken == null) {
        debugPrint('❌ Failed to get access token');
        return false;
      }

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM notification sent successfully');
        debugPrint('📱 Response: ${response.body}');
        return true;
      } else {
        debugPrint('❌ FCM request failed: ${response.statusCode}');
        debugPrint('📱 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM request: $e');
      return false;
    }
  }

  /// الحصول على access token (يجب تنفيذه في الخادم)
  Future<String?> _getAccessToken() async {
    // في بيئة الإنتاج، يجب تنفيذ هذا في الخادم الخلفي
    // باستخدام service account key
    debugPrint('⚠️ Access token should be generated on server side');
    
    // مثال للتوضيح - لا يعمل في الإنتاج
    return 'YOUR_ACCESS_TOKEN_HERE';
  }

  /// حفظ الإشعار في Firestore
  Future<void> _saveNotificationToFirestore({
    required String deviceToken,
    required String title,
    required String body,
    required String type,
    Map<String, String>? data,
  }) async {
    try {
      await _firestore.collection('sent_notifications').add({
        'deviceToken': deviceToken.substring(0, 20) + '...', // لا نحفظ التوكن كاملاً لأسباب أمنية
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      debugPrint('❌ Error saving notification to Firestore: $e');
    }
  }

  /// إرسال إشعار اختبار
  Future<bool> sendTestNotification(String deviceToken) async {
    return await sendAlertNotification(
      deviceToken: deviceToken,
      title: 'اختبار الإشعارات 🧪',
      body: 'هذا إشعار تجريبي للتأكد من عمل النظام بشكل صحيح',
      data: {
        'test': 'true',
        'source': 'fcm_v1_service',
      },
    );
  }
}
