import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // OLD LOGIC REMOVED
    // We now handle message saving entirely in Native Android (Kotlin)
    // to prevent race conditions and data loss.

    debugPrint("BACKGROUND_WORKER: Native handler active. Worker task skipped.");

    return Future.value(true);
  });
}