import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateManager {
  static final UpdateManager instance = UpdateManager._internal();
  UpdateManager._internal();

  /// Returns [true] if the current version is less than the required version.
  Future<bool> isUpdateRequired() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 12),
      ));

      // 2. Add a Real-Time Listener
      // This triggers AUTOMATICALLY whenever you hit "Publish" in the Firebase Console
      remoteConfig.onConfigUpdated.listen((RemoteConfigUpdate event) async {
        // Activate the new config immediately
        await remoteConfig.activate();

        // Optional: Notify your app to refresh UI
        // setState(() {});
      });

      // 3. Compare
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final requiredVersion = remoteConfig.getString('required_version');

      print("Version :$currentVersion");

      // If remote config is empty/failed, let user in
      if (requiredVersion.isEmpty) return false;

      return _isLowerThan(currentVersion, requiredVersion);
    } catch (e) {
      debugPrint("⚠️ Update Check Failed: $e");
      return false; // Allow access if check fails (e.g. offline)
    }
  }

  bool _isLowerThan(String current, String required) {
    List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> r = required.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < r.length; i++) {
      int cVal = (i < c.length) ? c[i] : 0;
      if (cVal < r[i]) return true; // Current is lower -> Update needed
      if (cVal > r[i]) return false; // Current is higher -> No update
    }
    return false;
  }
}

/// 🔒 A Simple Blocking App for Force Update
class ForceUpdateApp extends StatelessWidget {
  const ForceUpdateApp({super.key});

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_rounded, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "Update Required",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "A newer version of StatusHub is available. Please update to continue using the app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 16),

              /// 👇 CURRENT VERSION DISPLAY
              FutureBuilder<String>(
                future: _getVersion(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Text(
                    "Current Version: ${snapshot.data}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _launchPlayStore(),
                  child: const Text("Update Now"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchPlayStore() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final id = packageInfo.packageName;
    final url = Uri.parse("https://play.google.com/store/apps/details?id=$id");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}