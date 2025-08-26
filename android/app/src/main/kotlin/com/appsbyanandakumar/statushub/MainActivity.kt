package com.appsbyanandakumar.statushub

import android.media.MediaScannerConnection
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import android.os.Bundle
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel // Import the EventChannel class
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    // Your existing channels
    private val CHANNEL = "com.appsbyanandakumar.statushub/media_scanner"
    private val WEBP_CHANNEL = "com.appsbyanandakumar.statushub/convert_webp"
    private val WHATSAPP_CHANNEL = "com.appsbyanandakumar.statushub/open_whatsapp"

    // The new channel for the notification service
    private val NOTIFICATION_CHANNEL = "com.appsbyanandakumar.statushub/messages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing media scanner MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanMedia") {
                    val paths = call.argument<List<String>>("paths")
                    paths?.forEach { path ->
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            null,
                            null
                        )
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        // Existing WebP conversion MethodChannel
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

        // Existing WhatsApp home launcher MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openWhatsApp") {
                    val success = openWhatsAppHome()
                    result.success(success)
                } else {
                    result.notImplemented()
                }
            }

        // ✅ NEW: Add this EventChannel for the notification listener
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationListener.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    NotificationListener.eventSink = null
                }
            })
    }

    // Your existing functions (no changes needed)
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
}