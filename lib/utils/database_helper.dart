import 'dart:async'; // Import async library
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// The data model class (no changes needed)
class CapturedMessage {
  final int? id;
  final String sender;
  final String message;
  final String packageName;
  final DateTime timestamp;

  CapturedMessage({
    this.id,
    required this.sender,
    required this.message,
    required this.packageName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'packageName': packageName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // ✅ NEW: Add a StreamController to broadcast updates
  final _streamController = StreamController<void>.broadcast();

  // ✅ NEW: Expose the stream for the UI to listen to
  Stream<void> get onMessageAdded => _streamController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'messages.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL,
        message TEXT NOT NULL,
        packageName TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
      ''');
  }

  Future<int> insertMessage(CapturedMessage message) async {
    Database db = await instance.database;
    debugPrint("DATABASE_HELPER: Inserting message: '${message.message}'");
    final id = await db.insert('messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // ✅ NEW: After inserting, send a signal on the stream
    debugPrint("DATABASE_HELPER: Inserted with ID: $id. Broadcasting update.");
    _streamController.add(null);

    return id;
  }

  Future<List<CapturedMessage>> getMessages() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
    await db.query('messages', orderBy: 'timestamp DESC');
    debugPrint("DATABASE_HELPER: Fetched ${maps.length} messages from DB.");

    return List.generate(maps.length, (i) {
      return CapturedMessage(
        id: maps[i]['id'],
        sender: maps[i]['sender'],
        message: maps[i]['message'],
        packageName: maps[i]['packageName'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
      );
    });
  }

  // ✅ NEW: Good practice to add a dispose method
  void dispose() {
    _streamController.close();
  }
}