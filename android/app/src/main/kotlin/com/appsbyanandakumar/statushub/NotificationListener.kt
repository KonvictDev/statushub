package com.appsbyanandakumar.statushub

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class NotificationListener : NotificationListenerService() {

    // A companion object is Kotlin's way of creating static members
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)

        // Use Kotlin's null safety
        if (sbn == null) return

        val packageName = sbn.packageName
        // Check if the notification is from WhatsApp or WhatsApp Business
        if (packageName in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            val extras = sbn.notification.extras
            val sender = extras.getString("android.title")
            val message = extras.getString("android.text")

            // Ignore notifications without a sender or message
            if (sender == null || message == null) {
                return
            }

            // A simple check to avoid group message summaries (e.g., "2 new messages")
            if (message.contains(" new message", ignoreCase = true)) {
                return
            }

            // Use the handler to send data to Flutter on the main thread
            handler.post {
                // Use the safe call operator ?. to avoid null pointer exceptions
                eventSink?.success(
                    mapOf(
                        "sender" to sender,
                        "message" to message,
                        "packageName" to packageName
                    )
                )
            }
        }
    }
}