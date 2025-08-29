const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Function لإرسال الإشعارات الخارجية
exports.sendPushNotification = functions.firestore
  .document('fcm_queue/{docId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const { recipientId, title, body, data: notificationData } = data;

      // الحصول على FCM token للمستخدم
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(recipientId)
        .get();

      if (!userDoc.exists) {
        console.log('User not found:', recipientId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('No FCM token for user:', recipientId);
        return null;
      }

      // إعداد الإشعار
      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
          // The image must be a public URL. Replace this placeholder with your own hosted image.
          imageUrl: 'https://i.imgur.com/KV2p9AL.png',
        },
        data: {
          ...notificationData,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#1E88E5',
            sound: 'default',
            channelId: 'mybus_notifications',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // إرسال الإشعار
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);

      // تحديث حالة الإشعار
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      
      // تحديث حالة الإشعار بالخطأ
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

// Cloud Function لإرسال الإيميلات
exports.sendEmail = functions.firestore
  .document('email_queue/{docId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const { to, subject, html } = data;

      // هنا يمكن إضافة منطق إرسال الإيميل باستخدام SendGrid أو Nodemailer
      console.log('Email queued:', { to, subject });

      // تحديث حالة الإيميل
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return true;
    } catch (error) {
      console.error('Error sending email:', error);
      
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

// Cloud Function لتنظيف الإشعارات القديمة
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      // حذف الإشعارات الأقدم من 30 يوم
      const oldNotifications = await admin.firestore()
        .collection('notifications')
        .where('timestamp', '<', thirtyDaysAgo)
        .get();

      const batch = admin.firestore().batch();
      oldNotifications.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${oldNotifications.docs.length} old notifications`);

      // حذف FCM queue المرسلة
      const sentFcmQueue = await admin.firestore()
        .collection('fcm_queue')
        .where('status', '==', 'sent')
        .where('sentAt', '<', thirtyDaysAgo)
        .get();

      const fcmBatch = admin.firestore().batch();
      sentFcmQueue.docs.forEach(doc => {
        fcmBatch.delete(doc.ref);
      });

      await fcmBatch.commit();
      console.log(`Deleted ${sentFcmQueue.docs.length} old FCM queue items`);

      return null;
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
      return null;
    }
  });

// Cloud Function لإحصائيات الإشعارات
exports.updateNotificationStats = functions.firestore
  .document('notifications/{docId}')
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const { recipientId, type } = data;

      // تحديث إحصائيات المستخدم
      const userStatsRef = admin.firestore()
        .collection('user_stats')
        .doc(recipientId);

      await userStatsRef.set({
        totalNotifications: admin.firestore.FieldValue.increment(1),
        [`${type}Notifications`]: admin.firestore.FieldValue.increment(1),
        lastNotificationAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // تحديث إحصائيات عامة
      const globalStatsRef = admin.firestore()
        .collection('global_stats')
        .doc('notifications');

      await globalStatsRef.set({
        totalNotifications: admin.firestore.FieldValue.increment(1),
        [`${type}Notifications`]: admin.firestore.FieldValue.increment(1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return null;
    } catch (error) {
      console.error('Error updating notification stats:', error);
      return null;
    }
  });
