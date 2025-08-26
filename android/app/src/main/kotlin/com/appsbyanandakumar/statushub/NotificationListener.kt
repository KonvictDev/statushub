package com.appsbyanandakumar.statushub

import android.app.Notification
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        // Tag for filtering logs in Logcat
        private const val TAG = "NotificationListener"
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        if (packageName !in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            return
        }

        val notification = sbn.notification
        val extras = notification.extras
        val sender = extras.getString(Notification.EXTRA_TITLE)

        // --- Log all notification data for debugging ---
        logExtras(extras)

        // --- Definitive Message Extraction Logic ---

        // As revealed by your logs, the key is "android.messages"
        val messages = extras.getParcelableArray("android.messages")

        if (messages != null && messages.isNotEmpty()) {
            // This is a MessagingStyle notification with bundled messages.
            // The last message in the array is the newest one.
            val lastMessageBundle = messages.last() as? Bundle
            if (lastMessageBundle != null) {
                val messageText = lastMessageBundle.getString("text")
                // Sometimes the sender is in the bundle, otherwise use the main title
                val messageSender = lastMessageBundle.getString("sender") ?: sender

                if (messageSender != null && messageText != null) {
                    sendToFlutter(messageSender, messageText, packageName)
                }
            }
        } else {
            // This is a single message or a summary.
            val message = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            if (sender != null && message != null) {
                // We must filter out the summary notifications.
                if (!message.contains(" new message", ignoreCase = true)) {
                    sendToFlutter(sender, message, packageName)
                } else {
                    Log.d(TAG, "Ignoring summary notification: '$message'")
                }
            }
        }
    }

    private fun sendToFlutter(sender: String, message: String, packageName: String) {
        handler.post {
            val notificationData = mapOf(
                "sender" to sender,
                "message" to message,
                "packageName" to packageName
            )
            // This log confirms exactly what is being sent to your Flutter app
            Log.d(TAG, "SUCCESS - Sending to Flutter: $notificationData")
            eventSink?.success(notificationData)
        }
    }

    // Helper function to print all contents of a notification bundle
    private fun logExtras(extras: Bundle) {
        Log.d(TAG, "--- Start Notification Extras ---")
        for (key in extras.keySet()) {
            val value = extras.get(key)
            Log.d(TAG, "Key: $key, Value: $value, Type: ${value?.javaClass?.name}")
        }
        Log.d(TAG, "--- End Notification Extras ---")
    }
}