import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _hasShownRationale = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkIfPreviouslyDenied();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckPermission();
    }
  }

  Future<void> _checkIfPreviouslyDenied() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownRationale =
        prefs.getBool('has_shown_permission_rationale') ?? false;
  }

  Future<void> _storeDenialFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_permission_rationale', true);
  }

  Future<void> _recheckPermission() async {
    final granted = await _isPermissionGranted();
    if (granted) {
      widget.onPermissionGranted();
    }
  }

  Future<bool> _isPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    return await Permission.manageExternalStorage.isGranted;
  }

  Future<bool> _isPermanentlyDenied() async {
    return Platform.isAndroid &&
        await Permission.manageExternalStorage.isPermanentlyDenied;
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> _requestPermissionFlow() async {
    final granted = await _requestPermissions();
    if (granted) {
      widget.onPermissionGranted();
    } else {
      final permanentlyDenied = await _isPermanentlyDenied();
      if (permanentlyDenied) {
        _showSettingsDialog();
      } else {
        _showRationaleSheet(); // Always show rationale on soft denial
        await _storeDenialFlag(); // Optionally track once
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 150,
                    width: 150,
                    child: Lottie.asset(
                      'assets/lottie/folder_access.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Storage Permission Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'To access WhatsApp statuses:\n'
                  '• Allow "All files access" for the app\n'
                  '• This is required to read media stored by WhatsApp',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 32),

                FilledButton.icon(
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Grant Permission'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _requestPermissionFlow,
                ),

                const SizedBox(height: 16),

                TextButton.icon(
                  icon: const Icon(Icons.help_outline),
                  label: const Text('How to Grant Permission'),
                  onPressed: _showHelpDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Permission has been permanently denied.\n\n'
          'Please open app settings and allow access manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('How to Grant Permission'),
        content: const Text(
          '1. Tap "Grant Permission"\n'
          '2. Select "Allow access to all files" when prompted\n'
          '3. If denied, go to Settings → Apps → Your App → Permissions → Allow all files access',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRationaleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              // Vertically center the icon
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.folder_rounded,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why We Need This',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This permission lets the app read WhatsApp statuses, which are saved in protected folders due to Android’s privacy rules.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // 👈 Customize radius here
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _requestPermissionFlow();
                },
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
