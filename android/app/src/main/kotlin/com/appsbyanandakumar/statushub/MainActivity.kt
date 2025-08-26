package com.appsbyanandakumar.statushub

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    // Your existing channels
    private val MEDIA_SCANNER_CHANNEL = "com.appsbyanandakumar.statushub/media_scanner"
    private val WEBP_CHANNEL = "com.appsbyanandakumar.statushub/convert_webp"
    private val WHATSAPP_CHANNEL = "com.appsbyanandakumar.statushub/open_whatsapp"

    // The channel for the notification service
    private val NOTIFICATION_EVENT_CHANNEL = "com.appsbyanandakumar.statushub/messages"

    // ✅ NEW: The channel for handling permissions
    private val PERMISSION_METHOD_CHANNEL = "com.appsbyanandakumar.statushub/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- Your Existing MethodChannels (No changes needed) ---
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEBP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "convertToWebP") {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val webpBytes = convertToWebP(path)
                        if (webpBytes != null) {
                            result.success(webpBytes)
                        } else {
                            result.error("ERROR", "Failed to convert image to WebP", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Image path is null", null)
                    }
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

        // --- Notification EventChannel (Your implementation is correct) ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Use the static variable from your NotificationListener class
                    NotificationListener.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    NotificationListener.eventSink = null
                }
            })

        // ✅ NEW: Add this MethodChannel for checking and requesting permission ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "requestPermission" -> {
                    // This intent opens the specific system setting screen
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(null) // We don't need to return anything
                }
                else -> result.notImplemented()
            }
        }
    }

    // --- Your existing functions (no changes needed) ---
    private fun convertToWebP(path: String): ByteArray? {
        val bitmap = BitmapFactory.decodeFile(path) ?: return null
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, 100, outputStream)
        return outputStream.toByteArray()
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

    // ✅ NEW: Add this function to check if the listener is enabled ---
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