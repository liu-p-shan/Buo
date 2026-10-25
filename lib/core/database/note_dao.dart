import 'package:sqflite_sqlcipher/sqflite.dart';

/// 笔记模型(两空间共用)
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.pinned,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String content;
  final int color;
  final bool pinned;
  final bool deleted;
  final int createdAt; // epoch ms
  final int updatedAt; // epoch ms

  Note copyWith({
    String? title,
    String? content,
    int? color,
    bool? pinned,
    bool? deleted,
    int? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        color: color ?? this.color,
        pinned: pinned ?? this.pinned,
        deleted: deleted ?? this.deleted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'color': color,
        'pinned': pinned ? 1 : 0,
        'deleted': deleted ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int,
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        color: map['color'] as int? ?? 0,
        pinned: (map['pinned'] as int? ?? 0) == 1,
        deleted: (map['deleted'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
}

/// 笔记数据访问层(纯异步 API,不持有 UI 状态)
class NoteDao {
  NoteDao(this._db);

  final Database _db;

  /// 列表:置顶优先,其次按更新时间倒序;[keyword] 为标题/正文模糊搜索
  Future<List<Note>> listNotes({bool trash = false, String? keyword}) async {
    final where = <String>['deleted = ?'];
    final args = <Object>[trash ? 1 : 0];

    final kw = keyword?.trim();
    if (kw != null && kw.isNotEmpty) {
      final escaped = escapeLike(kw);
      where.add('(title LIKE ? ESCAPE \'\\\' OR content LIKE ? ESCAPE \'\\\')');
      args.addAll(['%$escaped%', '%$escaped%']);
    }

    final rows = await _db.query(
      'notes',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'pinned DESC, updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> getById(int id) async {
    final rows = await _db.query('notes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  Future<Note> create({
    required String title,
    required String content,
    int color = 0,
    bool pinned = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.insert('notes', {
      'title': title,
      'content': content,
      'color': color,
      'pinned': pinned ? 1 : 0,
      'deleted': 0,
      'created_at': now,
      'updated_at': now,
    });
    return Note(
      id: id,
      title: title,
      content: content,
      color: color,
      pinned: pinned,
      deleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> update(Note note) async {
    final next =
        note.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _db.update('notes', next.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> moveToTrash(int id) async {
    final note = await getById(id);
    if (note == null) return;
    await update(note.copyWith(deleted: true));
  }

  Future<void> restoreFromTrash(int id) async {
    final note = await getById(id);
    if (note == null) return;
    await update(note.copyWith(deleted: false));
  }

  Future<void> purge(int id) =>
      _db.delete('notes', where: 'id = ?', whereArgs: [id]);

  Future<void> emptyTrash() => _db.delete('notes', where: 'deleted = 1');

  Future<int> countActive() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE deleted = 0',
    );
    return rows.first['c'] as int? ?? 0;
  }

  /// LIKE 通配符转义(用户输入作为模式串时的注入防御)
  static String escapeLike(String input) => input
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}
