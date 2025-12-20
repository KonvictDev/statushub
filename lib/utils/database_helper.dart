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
      'timestamp': timestamp.millisecondsSinceEpoch.toString(),
      'notificationKey': notificationKey,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // Keep version at 2
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, 'messages.db');
    debugPrint("🔥 Flutter DB Path: $path");

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ✅ FIXED: Use rawQuery because PRAGMA returns a value ("wal")
  Future _onConfigure(Database db) async {
    await db.rawQuery('PRAGMA journal_mode = WAL');
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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute("DROP TABLE IF EXISTS messages");
    await _onCreate(db, newVersion);
  }

  Future<int> insertMessage(CapturedMessage message) async {
    Database db = await instance.database;
    return await db.insert('messages', message.toMap());
  }

  Future<List<CapturedMessage>> getNonDeletedMessages() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'isDeleted = 0',
      orderBy: 'id DESC',
    );
    return _mapToMessages(maps);
  }

  Future<int> markMessageAsDeleted(String notificationKey) async {
    Database db = await instance.database;
    return await db.update(
      'messages',
      {'isDeleted': 1},
      where: 'notificationKey = ?',
      whereArgs: [notificationKey],
    );
  }

  Future<int> deleteMultipleMessages(List<int> ids) async {
    if (ids.isEmpty) return 0;
    Database db = await instance.database;
    return await db.delete(
      'messages',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  List<CapturedMessage> _mapToMessages(List<Map<String, dynamic>> maps) {
    return List.generate(maps.length, (i) {
      return CapturedMessage(
        id: maps[i]['id'],
        sender: maps[i]['sender'],
        message: maps[i]['message'],
        packageName: maps[i]['packageName'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(maps[i]['timestamp'].toString()) ?? 0
        ),
        notificationKey: maps[i]['notificationKey'],
        isDeleted: maps[i]['isDeleted'] == 1,
      );
    });
  }
}