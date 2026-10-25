import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/security/app_lock_controller.dart';
import 'package:safemate/core/utils/log.dart';
import 'package:safemate/core/database/note_dao.dart';

/// 空间标识:真库 / 伪装库(槽位映射由凭据块决定)
enum VaultSpace { real, decoy }

/// 数据库打开失败(密钥不匹配 / 文件损坏)
class VaultOpenException implements Exception {
  const VaultOpenException(this.cause);

  final String cause;

  @override
  String toString() => 'VaultOpenException($cause)';
}

/// 双空间数据库管理器(SQLCipher)
///
/// 安全设计:
/// 1. 单活跃空间:任一时刻至多一个库处于打开状态;
/// 2. 密钥生命周期:密钥 hex 仅作为参数流经本类,不持有字段引用;
/// 3. 孤儿自愈:仅重置流程(allowOrphanReset)允许删除重建;
/// 4. 构造时向 AppLockController 注册锁定钩子:切后台 → closeAll。
class DatabaseManager {
  DatabaseManager._() {
    AppLockController.instance.registerLockHook(closeAll);
  }

  static final DatabaseManager instance = DatabaseManager._();

  static const int _schemaVersion = 1;

  Database? _db;
  VaultSpace? _activeSpace;
  NoteDao? _activeDao;

  VaultSpace? get activeSpace => _activeSpace;
  bool get isAnyOpen => _db?.isOpen ?? false;

  NoteDao get dao {
    final dao = _activeDao;
    if (dao == null) {
      throw StateError('vault not open — 锁定状态下 UI 不应触达数据层');
    }
    return dao;
  }

  /// 打开指定空间的库
  Future<NoteDao> open(
    VaultSpace space, {
    required String dbKeyHex,
    required String fileName,
    bool allowOrphanReset = false,
  }) async {
    if (_activeSpace == space && _db != null && _db!.isOpen) {
      return _activeDao!;
    }
    await closeAll();

    final file = p.join(await getDatabasesPath(), fileName);
    Database db;
    try {
      db = await _openAt(file, dbKeyHex);
    } on VaultOpenException {
      if (!allowOrphanReset) rethrow;
      Log.d('[SafeMate] orphan slot rebuild: $fileName');
      await deleteDatabase(file);
      db = await _openAt(file, dbKeyHex);
    }

    _db = db;
    _activeSpace = space;
    _activeDao = NoteDao(db);
    Log.d('[SafeMate] vault open (${space.name})');
    return _activeDao!;
  }

  /// 关闭当前库并丢弃全部引用(锁定钩子 / 切换空间时调用)
  Future<void> closeAll() async {
    final db = _db;
    _db = null;
    _activeSpace = null;
    _activeDao = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
    Log.d('[SafeMate] vaults closed');
  }

  /// 重置流程专用:抹除两个槽位的全部库文件(含 journal/wal)
  static Future<void> wipeAllFiles() async {
    final dir = await getDatabasesPath();
    for (final slot in [AppConstants.vaultSlotA, AppConstants.vaultSlotB]) {
      await deleteDatabase(p.join(dir, slot));
    }
    Log.d('[SafeMate] all vault files wiped');
  }

  Future<Database> _openAt(String path, String dbKeyHex) async {
    try {
      return await openDatabase(
        path,
        password: dbKeyHex,
        version: _schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
      );
    } on DatabaseException catch (e) {
      throw VaultOpenException(e.toString());
    }
  }

  // ── Schema(两空间结构完全一致,表结构差异本身就是旁证)──────

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL DEFAULT '',
        content     TEXT    NOT NULL DEFAULT '',
        color       INTEGER NOT NULL DEFAULT 0,
        pinned      INTEGER NOT NULL DEFAULT 0,
        deleted     INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_notes_updated ON notes(updated_at DESC)',
    );
    await db.execute('CREATE INDEX idx_notes_deleted ON notes(deleted)');
    await db.execute(
      'CREATE TABLE meta (k TEXT PRIMARY KEY, v TEXT NOT NULL)',
    );
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // 迁移阶梯:版本 1 起步,后续版本按 oldV 逐级执行
  }
}
