package com.appsbyanandakumar.statushub

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {

    // Your existing channels
    private val MEDIA_SCANNER_CHANNEL = "com.appsbyanandakumar.statushub/media_scanner"
    private val WEBP_CHANNEL = "com.appsbyanandakumar.statushub/convert_webp"
    private val WHATSAPP_CHANNEL = "com.appsbyanandakumar.statushub/open_whatsapp"

    // The channel for the notification service
    private val NOTIFICATION_EVENT_CHANNEL = "com.appsbyanandakumar.statushub/messages"

    // ✅ NEW: The channel for handling permissions
    private val PERMISSION_METHOD_CHANNEL = "com.appsbyanandakumar.statushub/permissions"

    // ✅ NEW: A reference to our listener instance
    // You don't need this, you should just set the static property.
    // private val notificationListener = NotificationListener()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanMedia") {
                    val paths = call.argument<List<String>>("paths")
                    paths?.forEach { path ->
                        MediaScannerConnection.scanFile(applicationContext, arrayOf(path), null, null)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }


        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openWhatsApp") {
                    val success = openWhatsAppHome()
                    result.success(success)
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Correct: Assign the sink to the companion object property
                    NotificationListener.eventSink = events
                    Log.d("MainActivity", "EventChannel onListen: eventSink is set.")

                    // ✅ NEW: Trigger the queue processing
                    // You need to call this on the class itself
                    NotificationListener.processQueue()
                }

                override fun onCancel(arguments: Any?) {
                    NotificationListener.eventSink = null
                    Log.d("MainActivity", "EventChannel onCancel: eventSink is null.")
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "requestPermission" -> {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }


    private fun openWhatsAppHome(): Boolean {
        val packages = listOf("com.whatsapp", "com.whatsapp.w4b")
        val pm: PackageManager = packageManager
        for (pkg in packages) {
            try {
                val intent: Intent? = pm.getLaunchIntentForPackage(pkg)
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    return true
                }
            } catch (e: Exception) {
                continue
            }
        }
        return false
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null) {
                    if (TextUtils.equals(pkgName, cn.packageName)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}