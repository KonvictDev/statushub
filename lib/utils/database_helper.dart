// lib/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// The data model for our captured messages
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

  // A method to convert our object to a map for database insertion
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
  // A private constructor to prevent multiple instances
  DatabaseHelper._privateConstructor();
  // The single, static instance of the class (Singleton pattern)
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Getter for the database. Initializes it if it's null.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initializes the database: gets the path and opens the database
  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'messages.db');
    return await openDatabase(path,
        version: 1,
        onCreate: _onCreate);
  }

  // Creates the database table when the database is first created
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

  // Method to insert a message into the database
  Future<int> insertMessage(CapturedMessage message) async {
    Database db = await instance.database;
    return await db.insert('messages', message.toMap());
  }

  // Method to get all messages from the database
  Future<List<CapturedMessage>> getMessages() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('messages', orderBy: 'timestamp DESC');

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
}