package com.example.kidsbus;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService;
import com.example.mybus.R;

public class MyFirebaseMessagingService extends FlutterFirebaseMessagingService {
    private static final String TAG = "MyFirebaseMsgService";
    private static final String CHANNEL_ID = "mybus_notifications";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        // تسجيل استلام الرسالة
        Log.d(TAG, "From: " + remoteMessage.getFrom());

        // التحقق من وجود بيانات في الرسالة
        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());
        }

        // التحقق من وجود إشعار في الرسالة
        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Message Notification Body: " + remoteMessage.getNotification().getBody());
            
            // عرض الإشعار مخصص لضمان الظهور
            sendNotification(
                remoteMessage.getNotification().getTitle(),
                remoteMessage.getNotification().getBody()
            );
        }

        // استدعاء الطريقة الأساسية لمعالجة Flutter
        super.onMessageReceived(remoteMessage);
    }

    @Override
    public void onNewToken(String token) {
        Log.d(TAG, "Refreshed token: " + token);
        
        // إرسال التوكن الجديد إلى الخادم
        sendRegistrationToServer(token);
        
        // استدعاء الطريقة الأساسية
        super.onNewToken(token);
    }

    /**
     * إرسال التوكن إلى الخادم
     */
    private void sendRegistrationToServer(String token) {
        // TODO: تنفيذ إرسال التوكن إلى الخادم
        Log.d(TAG, "Token sent to server: " + token);
    }

    /**
     * إنشاء وعرض إشعار مخصص
     */
    private void sendNotification(String title, String messageBody) {
        Intent intent = new Intent(this, com.example.mybus.MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent,
                PendingIntent.FLAG_IMMUTABLE);

        String channelId = CHANNEL_ID;
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        
        NotificationCompat.Builder notificationBuilder =
                new NotificationCompat.Builder(this, channelId)
                        .setSmallIcon(R.drawable.ic_notification)
                        .setContentTitle(title != null ? title : "كيدز باص")
                        .setContentText(messageBody)
                        .setAutoCancel(true)
                        .setSound(defaultSoundUri)
                        .setContentIntent(pendingIntent)
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                        .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                        .setShowWhen(true)
                        .setWhen(System.currentTimeMillis())
                        .setStyle(new NotificationCompat.BigTextStyle()
                                .bigText(messageBody)
                                .setBigContentTitle(title)
                                .setSummaryText("كيدز باص"));

        NotificationManager notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        // إنشاء قناة الإشعارات للأندرويد 8.0 وما فوق
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(channelId,
                    "كيدز باص - الإشعارات",
                    NotificationManager.IMPORTANCE_HIGH);
            channel.setDescription("إشعارات تطبيق كيدز باص للنقل المدرسي");
            channel.enableLights(true);
            channel.enableVibration(true);
            channel.setShowBadge(true);
            notificationManager.createNotificationChannel(channel);
        }

        notificationManager.notify(0, notificationBuilder.build());
        Log.d(TAG, "Custom notification sent successfully");
    }
}