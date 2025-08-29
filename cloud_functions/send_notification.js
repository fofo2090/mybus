const functions = require('firebase-functions');
const admin = require('firebase-admin');

// تهيئة Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function لإرسال إشعارات FCM باستخدام HTTP v1 API
 * يدعم إرسال الإشعارات للأجهزة المختلفة مع تحسينات خاصة لكل منصة
 */
exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    console.log('📤 Sending FCM notification...', data);

    // التحقق من المصادقة
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // التحقق من البيانات المطلوبة
    const { deviceToken, title, body, type = 'alert', data: customData = {} } = data;
    
    if (!deviceToken || !title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: deviceToken, title, body');
    }

    // إنشاء payload للإشعار
    const message = {
      token: deviceToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        timestamp: new Date().toISOString(),
        ...customData,
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'mybus_notifications',
          sound: 'default',
          icon: 'ic_notification',
          color: '#1E88E5',
          default_sound: true,
          default_vibrate_timings: true,
          default_light_settings: true,
          notification_priority: 'PRIORITY_MAX',
          visibility: 'PUBLIC',
          sticky: false,
          local_only: false,
        }
      },
      apns: {
        headers: {
          'apns-priority': '10'
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
            'mutable-content': 1,
          }
        }
      },
      webpush: {
        headers: {
          'Urgency': 'high'
        },
        notification: {
          title: title,
          body: body,
          icon: '/icons/icon-192x192.png',
          badge: '/icons/badge-72x72.png',
          vibrate: [200, 100, 200],
          requireInteraction: true,
        }
      }
    };

    // إرسال الإشعار
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent successfully:', response);

    // حفظ الإشعار في قاعدة البيانات
    await admin.firestore().collection('sent_notifications').add({
      deviceToken: deviceToken.substring(0, 20) + '...', // لا نحفظ التوكن كاملاً
      title: title,
      body: body,
      type: type,
      data: customData,
      response: response,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: context.auth.uid,
    });

    return {
      success: true,
      messageId: response,
      timestamp: new Date().toISOString(),
    };

  } catch (error) {
    console.error('❌ Error sending notification:', error);
    
    // حفظ الخطأ في قاعدة البيانات
    await admin.firestore().collection('notification_errors').add({
      error: error.message,
      data: data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: context.auth?.uid || 'unknown',
    });

    throw new functions.https.HttpsError('internal', 'Failed to send notification: ' + error.message);
  }
});

/**
 * Cloud Function لإرسال إشعارات لمجموعة من المستخدمين
 */
exports.sendBatchNotification = functions.https.onCall(async (data, context) => {
  try {
    console.log('📤 Sending batch FCM notifications...', data);

    // التحقق من المصادقة
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { deviceTokens, title, body, type = 'alert', data: customData = {} } = data;
    
    if (!deviceTokens || !Array.isArray(deviceTokens) || deviceTokens.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'deviceTokens must be a non-empty array');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: title, body');
    }

    // إنشاء multicast message
    const message = {
      tokens: deviceTokens,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        timestamp: new Date().toISOString(),
        ...customData,
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'mybus_notifications',
          sound: 'default',
          icon: 'ic_notification',
          color: '#1E88E5',
        }
      },
      apns: {
        headers: {
          'apns-priority': '10'
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
          }
        }
      }
    };

    // إرسال الإشعارات
    const response = await admin.messaging().sendMulticast(message);
    console.log('✅ Batch notifications sent:', response);

    // حفظ النتائج في قاعدة البيانات
    await admin.firestore().collection('batch_notifications').add({
      deviceTokenCount: deviceTokens.length,
      title: title,
      body: body,
      type: type,
      data: customData,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses.map(r => ({
        success: r.success,
        messageId: r.messageId,
        error: r.error?.message,
      })),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: context.auth.uid,
    });

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      totalCount: deviceTokens.length,
      timestamp: new Date().toISOString(),
    };

  } catch (error) {
    console.error('❌ Error sending batch notifications:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send batch notifications: ' + error.message);
  }
});

/**
 * Cloud Function لإرسال إشعار تجريبي
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  try {
    console.log('🧪 Sending test notification...');

    // التحقق من المصادقة
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { deviceToken } = data;
    
    if (!deviceToken) {
      throw new functions.https.HttpsError('invalid-argument', 'deviceToken is required');
    }

    // إنشاء إشعار تجريبي
    const message = {
      token: deviceToken,
      notification: {
        title: 'اختبار الإشعارات 🧪',
        body: 'هذا إشعار تجريبي للتأكد من عمل النظام بشكل صحيح',
      },
      data: {
        type: 'test',
        timestamp: new Date().toISOString(),
        source: 'cloud_function',
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'mybus_notifications',
          sound: 'default',
          icon: 'ic_notification',
          color: '#1E88E5',
        }
      },
      apns: {
        headers: {
          'apns-priority': '10'
        },
        payload: {
          aps: {
            alert: {
              title: 'اختبار الإشعارات 🧪',
              body: 'هذا إشعار تجريبي للتأكد من عمل النظام بشكل صحيح',
            },
            sound: 'default',
            badge: 1,
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Test notification sent successfully:', response);

    return {
      success: true,
      messageId: response,
      timestamp: new Date().toISOString(),
    };

  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send test notification: ' + error.message);
  }
});

/**
 * Cloud Function لإرسال إشعار data-only (صامت)
 */
exports.sendDataOnlyNotification = functions.https.onCall(async (data, context) => {
  try {
    console.log('📊 Sending data-only notification...');

    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { deviceToken, data: customData = {} } = data;
    
    if (!deviceToken) {
      throw new functions.https.HttpsError('invalid-argument', 'deviceToken is required');
    }

    const message = {
      token: deviceToken,
      data: {
        type: 'silentUpdate',
        timestamp: new Date().toISOString(),
        ...customData,
      },
      android: {
        priority: 'HIGH',
      },
      apns: {
        headers: {
          'apns-priority': '5'
        },
        payload: {
          aps: {
            'content-available': 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Data-only notification sent successfully:', response);

    return {
      success: true,
      messageId: response,
      timestamp: new Date().toISOString(),
    };

  } catch (error) {
    console.error('❌ Error sending data-only notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send data-only notification: ' + error.message);
  }
});
