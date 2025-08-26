// lib/background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../utils/database_helper.dart'; // Import your database helper

// The channel name must match the one in MainActivity.kt
const notificationChannel = EventChannel('com.appsbyanandakumar.statushub/messages'); // ✅ UPDATE THIS LINE


// This function is the entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // DartPluginRegistrant is needed to use plugins in a background isolate.
  DartPluginRegistrant.ensureInitialized();

  // The service can communicate with the UI using `invoke`
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listen for notifications from the native side
  notificationChannel.receiveBroadcastStream().listen((dynamic event) {
    if (event is Map) {
      final message = CapturedMessage(
        sender: event['sender'] ?? 'Unknown Sender',
        message: event['message'] ?? '',
        packageName: event['packageName'] ?? '',
        timestamp: DateTime.now(),
      );
      // Save the captured message to the database
      DatabaseHelper.instance.insertMessage(message);
    }
  });
}

// Function to initialize and start the background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(), // iOS configuration (not applicable for this feature)
  );

  service.startService();
}