package com.appsbyanandakumar.statushub

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class ProcessMessageWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {

    override fun doWork(): Result {
        return try {
            val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val db = MessagesDbHelper(applicationContext).writableDatabase

            // ✅ Handle multiple deleted messages
            val deletedKeysSet = prefs.getStringSet("flutter.deleted_notificationKeys", mutableSetOf()) ?: mutableSetOf()

            if (deletedKeysSet.isNotEmpty()) {
                val editor = prefs.edit()

                deletedKeysSet.forEach { key ->
                    val sender = prefs.getString("flutter.deleted_sender_$key", "Unknown")
                    val message = prefs.getString("flutter.deleted_message_$key", "⚠️ Message deleted before capture")
                    val packageName = prefs.getString("flutter.deleted_package_$key", "com.whatsapp")

                    // Check if this message already exists in DB
                    val cursor: Cursor? = db.query(
                        "messages",
                        arrayOf("id"),
                        "notificationKey = ?",
                        arrayOf(key),
                        null, null, null
                    )

                    if (cursor != null && cursor.moveToFirst()) {
                        // Update existing message
                        val values = ContentValues().apply {
                            put("isDeleted", 1)
                        }
                        db.update("messages", values, "notificationKey = ?", arrayOf(key))
                        Log.d("ProcessMessageWorker", "Marked message deleted for key: $key")
                    } else {
                        // Insert placeholder for deleted message
                        val values = ContentValues().apply {
                            put("sender", sender)
                            put("message", message)
                            put("packageName", packageName)
                            put("timestamp", System.currentTimeMillis().toString())
                            put("notificationKey", key)
                            put("isDeleted", 1)
                        }
                        db.insert("messages", null, values)
                        Log.d("ProcessMessageWorker", "Inserted placeholder deleted message for key: $key")
                    }
                    cursor?.close()

                    // Clean up individual keys
                    editor.remove("flutter.deleted_sender_$key")
                        .remove("flutter.deleted_message_$key")
                        .remove("flutter.deleted_package_$key")
                }

                // Clear the set
                editor.remove("flutter.deleted_notificationKeys")
                editor.apply()

                NotificationListener.processQueue()
                return Result.success()
            }

            // ✅ Handle new message
            val sender = prefs.getString("flutter.latest_sender", null)
            val message = prefs.getString("flutter.latest_message", null)
            val packageName = prefs.getString("flutter.latest_packageName", null)
            val notificationKey = prefs.getString("flutter.latest_notificationKey", null)

            if (sender != null && message != null && packageName != null && notificationKey != null) {
                val values = ContentValues().apply {
                    put("sender", sender)
                    put("message", message)
                    put("packageName", packageName)
                    put("timestamp", System.currentTimeMillis().toString())
                    put("notificationKey", notificationKey)
                    put("isDeleted", 0)
                }

                val id = db.insert("messages", null, values)
                Log.d("ProcessMessageWorker", "Inserted message id=$id: $sender → $message")

                prefs.edit()
                    .remove("flutter.latest_sender")
                    .remove("flutter.latest_message")
                    .remove("flutter.latest_packageName")
                    .remove("flutter.latest_notificationKey")
                    .apply()

                NotificationListener.processQueue()
            } else {
                Log.d("ProcessMessageWorker", "No new message data found.")
            }

            Result.success()
        } catch (e: Exception) {
            Log.e("ProcessMessageWorker", "Error: ${e.message}", e)
            Result.failure()
        }
    }
}

class MessagesDbHelper(context: Context) :
    SQLiteOpenHelper(context, "messages.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sender TEXT NOT NULL,
                message TEXT NOT NULL,
                packageName TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                notificationKey TEXT,
                isDeleted INTEGER NOT NULL DEFAULT 0
            )
            """
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS messages")
        onCreate(db)
    }
}