package com.appsbyanandakumar.statushub

import android.media.MediaScannerConnection
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.appsbyanandakumar.statushub/media_scanner"
    private val WEBP_CHANNEL = "com.appsbyanandakumar.statushub/convert_webp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing media scanner
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

        // New WebP conversion channel
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
    }

    // Function to convert PNG/JPG to WebP
    private fun convertToWebP(path: String): ByteArray? {
        val bitmap = BitmapFactory.decodeFile(path) ?: return null
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, 100, outputStream)
        return outputStream.toByteArray()
    }
}
