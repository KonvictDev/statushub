// lib/screens/recover_message_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/database_helper.dart';

class RecoverMessageScreen extends StatefulWidget {
  const RecoverMessageScreen({super.key});

  @override
  State<RecoverMessageScreen> createState() => _RecoverMessageScreenState();
}

class _RecoverMessageScreenState extends State<RecoverMessageScreen> {
  List<CapturedMessage> _messages = [];
  bool _isLoading = true;
  String _statusMessage = 'Loading messages...';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadMessages();
  }

  Future<void> _checkPermissionsAndLoadMessages() async {
    // This permission is for the UI, but the critical one is enabling the Listener in Settings
    var status = await Permission.notification.status;
    if (status.isDenied) {
      // Open app settings to let the user enable the Notification Listener Service manually
      setState(() {
        _isLoading = false;
        _statusMessage = 'To recover messages, please enable Notification Access for this app in your phone\'s settings.';
      });
      // A button in the UI should call openAppSettings()
      return;
    }

    _loadMessagesFromDb();
  }

  Future<void> _loadMessagesFromDb() async {
    setState(() { _isLoading = true; });

    // Fetch real data from the database
    final data = await DatabaseHelper.instance.getMessages();

    if (!mounted) return;

    setState(() {
      _messages = data;
      _isLoading = false;
      if (_messages.isEmpty) {
        _statusMessage = 'No messages have been captured yet. New WhatsApp messages will appear here after they arrive.';
      }
    });
  }

  // Helper to show a dialog and open settings
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('To capture messages, this app needs access to your notifications. Please enable it in the settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            openAppSettings();
            Navigator.pop(context);
          }, child: const Text('Open Settings')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovered Messages'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showPermissionDialog,
                child: const Text('Open Settings'),
              )
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadMessagesFromDb,
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[index];
            // Use a different icon for WhatsApp vs WhatsApp Business
            final isBusiness = msg.packageName == 'com.whatsapp.w4b';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBusiness ? Colors.green[800] : Colors.teal[400],
                  child: Icon(isBusiness ? Icons.business_center : Icons.person, color: Colors.white),
                ),
                title: Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(msg.message),
                trailing: Text(
                  '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}