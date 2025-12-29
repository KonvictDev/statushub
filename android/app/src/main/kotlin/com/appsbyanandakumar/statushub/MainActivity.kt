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

// ✅ ADDED THESE TWO MISSING IMPORTS
import java.io.File
import androidx.core.content.FileProvider
// ✅ 2. Import for Edge-to-Edge Fix (Safe Version)
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {

    private val MEDIA_SCANNER_CHANNEL = "com.appsbyanandakumar.statushub/media_scanner"
    private val WHATSAPP_CHANNEL = "com.appsbyanandakumar.statushub/open_whatsapp"
    private val NOTIFICATION_EVENT_CHANNEL = "com.appsbyanandakumar.statushub/messages"
    private val PERMISSION_METHOD_CHANNEL = "com.appsbyanandakumar.statushub/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ FIX: Enable Edge-to-Edge (Draw behind system bars)
        // This replaces 'enableEdgeToEdge()' and works on all Flutter versions
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // 1. Media Scanner Channel
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

        // 2. WhatsApp Opener Channel (Updated)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openWhatsApp" -> {
                        // Your existing logic to open WhatsApp
                        val success = openWhatsAppHome()
                        result.success(success)
                    }
                    "shareFile" -> {
                        // ✅ NEW: Native Share Logic
                        val path = call.argument<String>("path")
                        val isVideo = call.argument<Boolean>("isVideo") ?: false

                        if (path != null) {
                            shareFileToWhatsApp(path, isVideo)
                            result.success(true)
                        } else {
                            result.error("INVALID_PATH", "Path cannot be null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 3. Notification Event Channel (The Fix is Here)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationListener.eventSink = events
                    Log.d("MainActivity", "EventChannel onListen: eventSink is set.")

                    // ✅ FIXED: Call the new method 'notifyFlutter' instead of 'processQueue'
                    NotificationListener.notifyFlutter()
                }

                override fun onCancel(arguments: Any?) {
                    NotificationListener.eventSink = null
                    Log.d("MainActivity", "EventChannel onCancel: eventSink is null.")
                }
            })

        // 4. Permission Channel
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

    private fun shareFileToWhatsApp(path: String, isVideo: Boolean) {
        val file = File(path)
        if (!file.exists()) return

        // ❌ OLD (Plugin authority - caused the crash)
        // val authority = "$packageName.flutter.share_provider"

        // ✅ NEW (Your custom authority defined in Step 2)
        val authority = "$packageName.fileprovider"

        try {
            val uri = FileProvider.getUriForFile(context, authority, file)

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = if (isVideo) "video/*" else "image/*"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, "Sent via StatusHub")
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error sharing to WhatsApp: ${e.message}")
            e.printStackTrace()
        }
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