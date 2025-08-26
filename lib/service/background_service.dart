import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../utils/database_helper.dart';

const notificationChannel = EventChannel('com.appsbyanandakumar.statushub/messages');

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  notificationChannel.receiveBroadcastStream().listen((dynamic event) {
    // ✅ DEBUG PRINT 1: Check if the event is received from Kotlin
    debugPrint("BACKGROUND_SERVICE: Received event from native side: $event");

    if (event is Map) {
      final message = CapturedMessage(
        sender: event['sender'] ?? 'Unknown Sender',
        message: event['message'] ?? '',
        packageName: event['packageName'] ?? '',
        timestamp: DateTime.now(),
      );

      // ✅ DEBUG PRINT 2: Check if we are about to insert into the database
      debugPrint("BACKGROUND_SERVICE: Attempting to insert message for sender: ${message.sender}");
      DatabaseHelper.instance.insertMessage(message);
    }
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}