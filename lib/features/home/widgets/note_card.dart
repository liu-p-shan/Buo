import 'package:flutter/material.dart';

import 'package:safemate/core/database/note_dao.dart';
import 'package:safemate/core/theme/app_theme.dart';

/// 笔记卡片(配色索引 0..5)
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  static const List<Color> palette = [
    Color(0xFF3D7FFF), // 蓝
    Color(0xFF30A46C), // 绿
    Color(0xFFFFA640), // 橙
    Color(0xFF8E4EC6), // 紫
    Color(0xFFE5484D), // 红
    Color(0xFF0E9397), // 青
  ];

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  String get _dateLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) {
      return '今天 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (today.difference(that).inDays == 1) return '昨天';
    return '${d.month}月${d.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = palette[note.color % palette.length];
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  width: 4,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? '无标题' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (note.pinned)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('置顶',
                                style: TextStyle(fontSize: 10, color: color)),
                          ),
                      ],
                    ),
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                            height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(_dateLabel,
                        style:
                            TextStyle(fontSize: 11, color: scheme.outline)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
