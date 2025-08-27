import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/database_helper.dart';

class RecoverMessageScreen extends StatefulWidget {
  const RecoverMessageScreen({super.key});

  @override
  State<RecoverMessageScreen> createState() => _RecoverMessageScreenState();
}

class _RecoverMessageScreenState extends State<RecoverMessageScreen>
    with WidgetsBindingObserver {
  static const platform =
  MethodChannel('com.appsbyanandakumar.statushub/permissions');
  static const eventChannel =
  EventChannel('com.appsbyanandakumar.statushub/messages');

  List<CapturedMessage> _messages = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _statusMessage = 'Loading messages...';
  StreamSubscription? _eventSubscription;

  // Selection state
  final Set<int> _selectedMessageIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndLoadMessages();
    _startListeningToNativeEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndLoadMessages();
    }
  }

  void _startListeningToNativeEvents() {
    _eventSubscription?.cancel(); // avoid duplicate listeners
    _eventSubscription =
        eventChannel.receiveBroadcastStream().listen((event) {
          debugPrint(
              "UI_SCREEN: Received signal from native. Reloading messages.");
          _loadMessagesFromDb();
        }, onError: (error) {
          debugPrint("UI_SCREEN: Error listening to native events: $error");
        });
  }

  Future<void> _checkPermissionAndLoadMessages() async {
    if (mounted) setState(() => _isLoading = true);
    final hasPermission = await _checkNotificationListenerPermission();
    _hasPermission = hasPermission;

    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage =
          'To recover messages, please enable Notification Access for this app in your phone\'s settings.';
        });
      }
      return;
    }
    await _loadMessagesFromDb();
  }

  Future<bool> _checkNotificationListenerPermission() async {
    try {
      return await platform.invokeMethod('checkPermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  Future<void> _loadMessagesFromDb() async {
    final data = await DatabaseHelper.instance.getNonDeletedMessages();
    if (!mounted) return;
    setState(() {
      _messages = data;
      _isLoading = false;
      if (_messages.isEmpty) {
        _statusMessage =
        'No messages have been captured yet.\nNew WhatsApp messages will appear here after they arrive.';
      }
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedMessageIds.contains(id)) {
        _selectedMessageIds.remove(id);
        if (_selectedMessageIds.isEmpty) _selectionMode = false;
      } else {
        _selectedMessageIds.add(id);
        _selectionMode = true;
      }
    });
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;
    await DatabaseHelper.instance
        .deleteMultipleMessages(_selectedMessageIds.toList());
    setState(() {
      _messages.removeWhere((msg) => _selectedMessageIds.contains(msg.id));
      _selectedMessageIds.clear();
      _selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedMessageIds.length} selected')
            : const Text('Recovered Messages'),
        actions: _selectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSelectedMessages,
          )
        ]
            : [],
        scrolledUnderElevation: 2,
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
            ListView(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _buildMessageCard(_messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageCard(CapturedMessage msg) {
    final isSelected = _selectedMessageIds.contains(msg.id);
    final isBusiness = msg.packageName == 'com.whatsapp.w4b';
    final colorScheme = Theme.of(context).colorScheme;

    final timestampStr =
        "${msg.timestamp.day.toString().padLeft(2, '0')}/"
        "${msg.timestamp.month.toString().padLeft(2, '0')} "
        "${msg.timestamp.hour.toString().padLeft(2, '0')}:"
        "${msg.timestamp.minute.toString().padLeft(2, '0')}";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.5) : null,
      child: ListTile(
        onLongPress: () => _toggleSelection(msg.id!),
        onTap: () {
          if (_selectionMode) {
            _toggleSelection(msg.id!);
          }
        },
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: _selectionMode
            ? Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleSelection(msg.id!),
        )
            : CircleAvatar(
          backgroundColor: isBusiness
              ? colorScheme.tertiaryContainer
              : colorScheme.primaryContainer,
          child: Icon(
            isBusiness ? Icons.business_center : Icons.person,
            color: isBusiness
                ? colorScheme.onTertiaryContainer
                : colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          msg.sender,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          msg.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Text(
          timestampStr,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequestUI() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 80, color: colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                try {
                  await platform.invokeMethod('requestPermission');
                } catch (e) {
                  debugPrint("Error opening settings: $e");
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            )
          ],
        ),
      ),
    );
  }
}
