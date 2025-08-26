import 'dart:async'; // Import async library
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/database_helper.dart';

class RecoverMessageScreen extends StatefulWidget {
  const RecoverMessageScreen({super.key});

  @override
  State<RecoverMessageScreen> createState() => _RecoverMessageScreenState();
}

class _RecoverMessageScreenState extends State<RecoverMessageScreen> {
  static const platform = MethodChannel('com.appsbyanandakumar.statushub/permissions');

  List<CapturedMessage> _messages = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _statusMessage = 'Loading messages...';

  // ✅ NEW: A variable to hold our stream subscription
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadMessages();

    // ✅ NEW: Listen to the database stream
    // When a new message is added, this will call _loadMessagesFromDb
    _messageSubscription = DatabaseHelper.instance.onMessageAdded.listen((_) {
      debugPrint("UI_SCREEN: Received update signal from database. Reloading messages.");
      _loadMessagesFromDb();
    });
  }

  @override
  void dispose() {
    debugPrint("UI_SCREEN: dispose called.");
    // ✅ NEW: Cancel the subscription to prevent memory leaks
    _messageSubscription?.cancel();
    super.dispose();
  }

  // The rest of your code in this file remains exactly the same.
  // No changes are needed below this line.

  Future<bool> _checkNotificationListenerPermission() async {
    try {
      return await platform.invokeMethod('checkPermission');
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  Future<void> _requestNotificationListenerPermission() async {
    try {
      await platform.invokeMethod('requestPermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'.");
    }
  }

  Future<void> _checkPermissionAndLoadMessages() async {
    if (mounted) setState(() => _isLoading = true);

    bool hasPermission = await _checkNotificationListenerPermission();
    _hasPermission = hasPermission;

    if (!_hasPermission) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'To recover messages, please enable Notification Access for this app in your phone\'s settings.';
        });
      }
      return;
    }

    await _loadMessagesFromDb();
  }

  Future<void> _loadMessagesFromDb() async {
    debugPrint("UI_SCREEN: _loadMessagesFromDb called.");
    final data = await DatabaseHelper.instance.getMessages();
    if (!mounted) return;
    debugPrint("UI_SCREEN: Setting state with ${data.length} messages.");
    setState(() {
      _messages = data;
      _isLoading = false;
      if (_messages.isEmpty) {
        _statusMessage = 'No messages have been captured yet. New WhatsApp messages will appear here after they arrive.';
      }
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('To capture messages, this app needs access to your notifications. Please enable it in the settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestNotificationListenerPermission();
              await Future.delayed(const Duration(seconds: 1));
              _checkPermissionAndLoadMessages();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovered Messages'),
        backgroundColor: Colors.teal.shade700,
        elevation: 2,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasPermission) {
      return _buildPermissionRequestUI();
    }
    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMessagesFromDb,
        child: Stack(
          children: [
            ListView(), // This makes RefreshIndicator work on an empty screen
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMessagesFromDb,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isBusiness = msg.packageName == 'com.whatsapp.w4b';
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isBusiness ? Colors.green.shade800 : Colors.teal.shade400,
                child: Icon(isBusiness ? Icons.business_center : Icons.person, color: Colors.white),
              ),
              title: Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(msg.message, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequestUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade500),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _showPermissionDialog,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            )
          ],
        ),
      ),
    );
  }
}