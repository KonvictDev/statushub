import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/database_helper.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("BACKGROUND_WORKER: Task started.");

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Corrected key
      final deletedNotificationKey = prefs.getString('flutter.deleted_notificationKey');
      if (deletedNotificationKey != null) {
        await DatabaseHelper.instance.markMessageAsDeleted(deletedNotificationKey);
        await prefs.remove('flutter.deleted_notificationKey');
        return Future.value(true);
      }

      final sender = prefs.getString('flutter.latest_sender');
      final message = prefs.getString('flutter.latest_message');
      final packageName = prefs.getString('flutter.latest_packageName');
      final notificationKey = prefs.getString('flutter.latest_notificationKey');

      if (sender != null && message != null && packageName != null && notificationKey != null) {
        final capturedMessage = CapturedMessage(
          sender: sender,
          message: message,
          packageName: packageName,
          timestamp: DateTime.now(),
          notificationKey: notificationKey,
        );

        await DatabaseHelper.instance.insertMessage(capturedMessage);

        // clear prefs
        await prefs.remove('flutter.latest_sender');
        await prefs.remove('flutter.latest_message');
        await prefs.remove('flutter.latest_packageName');
        await prefs.remove('flutter.latest_notificationKey');
      } else {
        debugPrint("BACKGROUND_WORKER: No new message data.");
      }
    } catch (e) {
      debugPrint("BACKGROUND_WORKER: Error $e");
      return Future.value(false);
    }

    return Future.value(true);
  });
}
