import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:statushub/service/status_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _errorMessage;

  // Track permissions
  bool _hasStoragePermission = false;
  bool _hasFolderAccess = false;

  // Track OS version to adjust UI
  bool _isAndroid13OrHigher = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndroidVersion();
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialPermissions();
    }
  }

  Future<void> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (mounted) {
        setState(() {
          _isAndroid13OrHigher = androidInfo.version.sdkInt >= 33;
        });
      }
    }
  }

  Future<void> _checkInitialPermissions() async {
    // FIX 1: Check mounted before setting state
    if (mounted) setState(() => _isLoading = true);

    // 1. Check Standard Storage (Gallery)
    bool storage = await _checkStoragePermission();

    // 2. Check WhatsApp Folder
    bool folder = await StatusService.hasPermission(WhatsAppType.whatsapp);

    if (!mounted) return; // Stop if the widget is gone

    if (storage && folder) {
      widget.onPermissionGranted();
    } else {
      // FIX 2: Check mounted again
      if (mounted) {
        setState(() {
          _hasStoragePermission = storage;
          _hasFolderAccess = folder;
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // On Android 13+ (SDK 33), we DO NOT need standard storage permission.
      if (androidInfo.version.sdkInt >= 33) {
        return true;
      }

      // For Android 12 and below, we check the actual permission
      return await Permission.storage.isGranted;
    }
    return true;
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        _checkInitialPermissions();
        return;
      }

      await Permission.storage.request();
      _checkInitialPermissions();
    }
  }

  Future<void> _requestFolderAccess() async {
    if (mounted) setState(() => _isLoading = true);

    await StatusService.requestPermission(WhatsAppType.whatsapp);

    await _checkInitialPermissions();

    // FIX 3: Check mounted
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_shared_outlined, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Permissions Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'To save and view statuses, we need access permission:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // --- 1. Storage Permission Card ---
              if (!_isAndroid13OrHigher) ...[
                _buildPermissionCard(
                  title: "1. Gallery Access",
                  subtitle: "Required to display the saved statuses.",
                  isGranted: _hasStoragePermission,
                  onTap: _requestStoragePermission,
                  buttonText: "Allow Access",
                ),
                const SizedBox(height: 16),
              ],

              // --- 2. WhatsApp Folder Card ---
              _buildPermissionCard(
                title: _isAndroid13OrHigher ? "WhatsApp Status Access" : "2. WhatsApp Status Access",
                subtitle: "Required to fetch new statuses.",
                isGranted: _hasFolderAccess,
                onTap: _requestFolderAccess,
                buttonText: "Select Folder",
              ),

              const SizedBox(height: 32),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle : Icons.circle_outlined,
                color: isGranted ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 8, bottom: 12),
            child: Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ),
          if (!isGranted)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
                child: Text(buttonText),
              ),
            ),
        ],
      ),
    );
  }
}