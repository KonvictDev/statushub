package com.appsbyanandakumar.statushub

import android.app.Notification
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit
import io.flutter.plugin.common.EventChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        var eventSink: EventChannel.EventSink? = null
        private val handler = Handler(Looper.getMainLooper())

        fun processQueue() {
            handler.post {
                eventSink?.success("refresh")
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        if (packageName !in listOf("com.whatsapp", "com.whatsapp.w4b")) return

        val extras = sbn.notification.extras
        val sender = extras.getString(Notification.EXTRA_TITLE)
        val notificationKey = sbn.key

        if (sender == null || notificationKey == null) return
        if (sender.contains("WhatsApp", ignoreCase = true) || sender.equals("You", ignoreCase = true)) return

        // 📌 Get all lines (group chats / multiple messages)
        val bigTextLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        val fallbackMessage = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

        // Store all messages in a list with their original order
        val allMessages = mutableListOf<String>()

        // Add individual messages first
        bigTextLines?.forEach { line ->
            line?.toString()?.let { allMessages.add(it) }
        }

        // Add fallback message if no individual lines exist
        if (allMessages.isEmpty() && fallbackMessage != null) {
            allMessages.add(fallbackMessage)
        }

        // Store all messages in shared preferences for potential future deletion
        storeMessagesForDeletionTracking(applicationContext, notificationKey, allMessages, sender, packageName)

        allMessages.forEach { message ->
            when {
                // Skip summary lines like "7 new messages"
                message.matches(Regex("\\d+ new messages", RegexOption.IGNORE_CASE)) -> {
                    Log.d(TAG, "Skipping summary: $message")
                }

                // Deleted message - handle immediately
                message.contains("This message was deleted", ignoreCase = true) ||
                        message.contains("⚠️ This message was deleted", ignoreCase = true) -> {
                    handleDeletedMessages(applicationContext, notificationKey, sender, packageName)
                }

                // Normal chat message
                else -> {
                    saveAndScheduleWork(applicationContext, sender, message, packageName, notificationKey)
                }
            }
        }
    }

    private fun storeMessagesForDeletionTracking(
        context: Context,
        notificationKey: String,
        messages: List<String>,
        sender: String,
        packageName: String
    ) {
        handler.post {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val messagesJson = messages.joinToString("|||") // Simple delimiter

                with(prefs.edit()) {
                    putString("flutter.pending_messages_$notificationKey", messagesJson)
                    putString("flutter.pending_sender_$notificationKey", sender)
                    putString("flutter.pending_package_$notificationKey", packageName)
                    apply()
                }
                Log.d(TAG, "✅ Stored ${messages.size} messages for tracking: $notificationKey")

            } catch (e: Exception) {
                Log.e(TAG, "Error storing messages for deletion tracking: ${e.message}")
            }
        }
    }

    private fun handleDeletedMessages(
        context: Context,
        notificationKey: String,
        sender: String,
        packageName: String
    ) {
        handler.post {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val messagesJson = prefs.getString("flutter.pending_messages_$notificationKey", null)
                val storedPackageName = prefs.getString("flutter.pending_package_$notificationKey", packageName) ?: packageName

                if (messagesJson != null) {
                    val messages = messagesJson.split("|||")

                    // Mark all pending messages as deleted
                    messages.forEach { message ->
                        if (!message.matches(Regex("\\d+ new messages", RegexOption.IGNORE_CASE))) {
                            saveDeletedMessage(context, notificationKey, sender, message, storedPackageName)
                        }
                    }

                    // Clean up
                    with(prefs.edit()) {
                        remove("flutter.pending_messages_$notificationKey")
                        remove("flutter.pending_sender_$notificationKey")
                        remove("flutter.pending_package_$notificationKey")
                        apply()
                    }

                    Log.d(TAG, "⚠️ Marked ${messages.size} messages deleted for key: $notificationKey")
                } else {
                    // Fallback: if we don't have stored messages, just mark by key
                    saveDeletedMessage(context, notificationKey, sender, "Unknown message", storedPackageName)
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error in handleDeletedMessages: ${e.message}")
            }
        }
    }

    private fun saveDeletedMessage(
        context: Context,
        notificationKey: String,
        sender: String,
        message: String,
        packageName: String
    ) {
        handler.post {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val deletedMessages = prefs.getStringSet("flutter.deleted_notificationKeys", mutableSetOf()) ?: mutableSetOf()

                // Store the deletion info with more context
                with(prefs.edit()) {
                    putString("flutter.deleted_sender_$notificationKey", sender)
                    putString("flutter.deleted_message_$notificationKey", message)
                    putString("flutter.deleted_package_$notificationKey", packageName)
                    putStringSet("flutter.deleted_notificationKeys", deletedMessages + notificationKey)
                    apply()
                }

                Log.d(TAG, "⚠️ Saved deleted message info for key: $notificationKey")

                val workRequest = OneTimeWorkRequest.Builder(ProcessMessageWorker::class.java)
                    .build()
                WorkManager.getInstance(context).enqueue(workRequest)

            } catch (e: Exception) {
                Log.e(TAG, "Error in saveDeletedMessage: ${e.message}")
            }
        }
    }

    private fun saveAndScheduleWork(
        context: Context,
        sender: String,
        message: String,
        packageName: String,
        notificationKey: String
    ) {
        handler.post {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                with(prefs.edit()) {
                    putString("flutter.latest_sender", sender)
                    putString("flutter.latest_message", message)
                    putString("flutter.latest_packageName", packageName)
                    putString("flutter.latest_notificationKey", notificationKey)
                    apply()
                }
                Log.d(TAG, "✅ Saved message from '$sender': '$message'")

                val workRequest = OneTimeWorkRequest.Builder(ProcessMessageWorker::class.java)
                    .setInitialDelay(300, TimeUnit.MILLISECONDS)
                    .build()
                WorkManager.getInstance(context).enqueue(workRequest)

            } catch (e: Exception) {
                Log.e(TAG, "Error in saveAndScheduleWork: ${e.message}")
            }
        }
    }
}