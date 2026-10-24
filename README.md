import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DbHelper {
  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  static const String dbNameReal = 'vault_a.db';
  static const String dbNameDecoy = 'vault_b.db';
  Database? _db;
  String? currentDbName;

  bool get isOpen => _db?.isOpen ?? false;

  Future<Database> open(String hexKey, {String dbName = dbNameReal}) async {
    if (_db != null && _db!.isOpen) {
      if (currentDbName == dbName) return _db!;
      await close();
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    _db = await openDatabase(
      path,
      password: hexKey,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
    currentDbName = dbName;
    return _db!;
  }

  static String generateHexKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    currentDbName = null;
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = _db;
    if (db == null) throw StateError('Locked');
    return await db.query('notes', orderBy: 'updated_at DESC');
  }

  Future<int> insertNote(String title, String content) async {
    final db = _db;
    if (db == null) throw StateError('Locked');
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('notes', {'title': title, 'content': content, 'created_at': now, 'updated_at': now});
  }
}
