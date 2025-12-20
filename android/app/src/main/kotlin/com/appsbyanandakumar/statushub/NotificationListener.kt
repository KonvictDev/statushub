package com.appsbyanandakumar.statushub

import android.app.Notification
import android.content.ContentValues
import android.database.Cursor
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        var eventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun notifyFlutter() {
            mainHandler.post {
                eventSink?.success("refresh")
            }
        }
    }

    private lateinit var dbHandler: Handler
    private lateinit var dbThread: HandlerThread

    override fun onCreate() {
        super.onCreate()
        dbThread = HandlerThread("MsgDbThread")
        dbThread.start()
        dbHandler = Handler(dbThread.looper)
    }

    override fun onDestroy() {
        dbThread.quitSafely()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName
        if (packageName !in listOf("com.whatsapp", "com.whatsapp.w4b")) return

        val extras = sbn.notification.extras
        val sender = extras.getString(Notification.EXTRA_TITLE)
        val notificationKey = sbn.key

        if (sender == null || notificationKey == null) return
        if (sender.contains("WhatsApp", ignoreCase = true) || sender.equals("You", ignoreCase = true)) return

        val bigTextLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        val fallbackMessage = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val allMessages = mutableListOf<String>()

        bigTextLines?.forEach { line -> line?.toString()?.let { allMessages.add(it) } }

        if (allMessages.isEmpty() && fallbackMessage != null) {
            allMessages.add(fallbackMessage)
        }

        dbHandler.post {
            processMessages(sender, packageName, notificationKey, allMessages)
        }
    }

    private fun processMessages(
        sender: String,
        packageName: String,
        notificationKey: String,
        messages: List<String>
    ) {
        val dbHelper = MessagesDbHelper(applicationContext)
        dbHelper.writableDatabase.use { db ->
            try {
                var hasNewData = false

                messages.forEach { message ->
                    if (isSummaryOrIgnored(message)) return@forEach

                    // --- 1. HANDLE DELETION ---
                    if (message.contains("This message was deleted", ignoreCase = true)) {
                        val values = ContentValues().apply { put("isDeleted", 1) }
                        // Mark the most recent non-deleted message from this sender as deleted
                        val rows = db.update(
                            "messages",
                            values,
                            "sender = ? AND packageName = ? AND isDeleted = 0",
                            arrayOf(sender, packageName)
                        )
                        if (rows > 0) {
                            Log.d(TAG, "🗑️ Marked message deleted from $sender")
                            hasNewData = true
                        }
                    }
                    // --- 2. HANDLE NEW MESSAGE (With Deduplication) ---
                    else {
                        // CHECK IF EXISTS FIRST
                        if (!checkIfMessageExists(db, sender, message, packageName)) {
                            val values = ContentValues().apply {
                                put("sender", sender)
                                put("message", message)
                                put("packageName", packageName)
                                put("timestamp", System.currentTimeMillis().toString())
                                put("notificationKey", notificationKey)
                                put("isDeleted", 0)
                            }
                            db.insert("messages", null, values)
                            Log.d(TAG, "📥 Saved: $sender -> $message")
                            hasNewData = true
                        } else {
                            // Log.v(TAG, "Duplicate ignored: $message")
                        }
                    }
                }

                // Only notify Flutter if we actually changed something
                if (hasNewData) {
                    notifyFlutter()
                }

            } catch (e: Exception) {
                Log.e(TAG, "Database error: ${e.message}")
            }
        }
    }

    // ✅ HELPER: Check DB for existing message to prevent duplicates
    private fun checkIfMessageExists(
        db: android.database.sqlite.SQLiteDatabase,
        sender: String,
        message: String,
        packageName: String
    ): Boolean {
        val cursor: Cursor = db.query(
            "messages",
            arrayOf("id"), // Select just ID is faster
            "sender = ? AND message = ? AND packageName = ?",
            arrayOf(sender, message, packageName),
            null, null, null
        )
        val exists = cursor.count > 0
        cursor.close()
        return exists
    }

    private fun isSummaryOrIgnored(msg: String): Boolean {
        return msg.matches(Regex("\\d+ new messages", RegexOption.IGNORE_CASE)) ||
                msg.contains("Checking for new messages", ignoreCase = true)
    }
}