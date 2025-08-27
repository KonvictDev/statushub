import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CapturedMessage {
  final int? id;
  final String sender;
  final String message;
  final String packageName;
  final DateTime timestamp;
  final String? notificationKey;
  final bool isDeleted;

  CapturedMessage({
    this.id,
    required this.sender,
    required this.message,
    required this.packageName,
    required this.timestamp,
    this.notificationKey,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'packageName': packageName,
      'timestamp': timestamp.toIso8601String(),
      'notificationKey': notificationKey,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

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
        timestamp TEXT NOT NULL,
        notificationKey TEXT,
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// ✅ Always inserts a new row, never replaces
  Future<int> insertMessage(CapturedMessage message) async {
    Database db = await instance.database;
    debugPrint("DATABASE_HELPER: Inserting message: '${message.message}'");
    final id = await db.insert('messages', message.toMap());
    return id;
  }

  /// ✅ Get ALL messages (including deleted)
  Future<List<CapturedMessage>> getMessages() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
    await db.query('messages', orderBy: 'timestamp DESC');
    debugPrint("DATABASE_HELPER: Raw rows = $maps");
    debugPrint("DATABASE_HELPER: Fetched ${maps.length} messages from DB.");
    return _mapToMessages(maps);
  }

  /// ✅ Get only non-deleted messages
  Future<List<CapturedMessage>> getNonDeletedMessages() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'isDeleted = 0',
      orderBy: 'timestamp DESC',
    );
    debugPrint("DATABASE_HELPER: Fetched ${maps.length} non-deleted messages.");
    return _mapToMessages(maps);
  }

  /// Soft delete
  Future<int> markMessageAsDeleted(String notificationKey) async {
    Database db = await instance.database;
    final rowsUpdated = await db.update(
      'messages',
      {'isDeleted': 1},
      where: 'notificationKey = ?',
      whereArgs: [notificationKey],
    );
    debugPrint("DATABASE_HELPER: Marked $rowsUpdated message(s) as deleted.");
    return rowsUpdated;
  }

  /// Hard delete single
  Future<int> deleteMessage(int id) async {
    Database db = await instance.database;
    final rowsDeleted = await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint("DATABASE_HELPER: Deleted $rowsDeleted message(s) with id=$id");
    return rowsDeleted;
  }

  /// Hard delete multiple
  Future<int> deleteMultipleMessages(List<int> ids) async {
    if (ids.isEmpty) return 0;
    Database db = await instance.database;
    final rowsDeleted = await db.delete(
      'messages',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    debugPrint("DATABASE_HELPER: Deleted $rowsDeleted messages with ids=$ids");
    return rowsDeleted;
  }

  List<CapturedMessage> _mapToMessages(List<Map<String, dynamic>> maps) {
    return List.generate(maps.length, (i) {
      return CapturedMessage(
        id: maps[i]['id'],
        sender: maps[i]['sender'],
        message: maps[i]['message'],
        packageName: maps[i]['packageName'],
        timestamp: DateTime.tryParse(maps[i]['timestamp']) ??
            DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(maps[i]['timestamp']) ?? 0),
        notificationKey: maps[i]['notificationKey'],
        isDeleted: maps[i]['isDeleted'] == 1,
      );
    });
  }
}
