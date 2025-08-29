package com.example.mybus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            // High importance channel for urgent notifications
            val highChannel = NotificationChannel(
                "mybus_notifications",
                "MyBus Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات تطبيق MyBus للطلاب والمشرفين"
                setSound(android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION), null)
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.parseColor("#FF6B6B")
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            // Default channel for general notifications
            val defaultChannel = NotificationChannel(
                "default_notifications",
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "إشعارات عامة للتطبيق"
                setSound(android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION), null)
                enableVibration(true)
                setShowBadge(true)
            }

            // Emergency channel for critical alerts
            val emergencyChannel = NotificationChannel(
                "emergency_notifications",
                "Emergency Alerts",
                NotificationManager.IMPORTANCE_MAX
            ).apply {
                description = "تنبيهات طوارئ مهمة"
                setSound(android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM), null)
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.RED
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setBypassDnd(true) // Bypass Do Not Disturb
            }

            // Create the channels
            notificationManager.createNotificationChannel(highChannel)
            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(emergencyChannel)
        }
    }
}
