import 'package:flutter/material.dart';

import 'package:safemate/core/database/database_manager.dart';
import 'package:safemate/core/database/note_dao.dart';
import 'package:safemate/core/theme/app_theme.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Note> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await DatabaseManager.instance.dao.listNotes(trash: true);
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ImmersiveStatusBar.dark(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 自绘标题栏 ──
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text('回收站',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: _items.isEmpty
                        ? null
                        : () async {
                            await DatabaseManager.instance.dao.emptyTrash();
                            _reload();
                          },
                    child: const Text('清空',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text('回收站是空的',
                            style: TextStyle(color: scheme.outline)))
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final note = _items[i];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            tileColor: scheme.surfaceContainerLow,
                            title: Text(
                                note.title.isEmpty ? '无标题' : note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                DateTime.fromMillisecondsSinceEpoch(
                                        note.updatedAt)
                                    .toString()
                                    .substring(0, 16),
                                style: TextStyle(
                                    fontSize: 12, color: scheme.outline)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore,
                                      color: AppColors.success),
                                  tooltip: '恢复',
                                  onPressed: () async {
                                    await DatabaseManager.instance.dao
                                        .restoreFromTrash(note.id);
                                    _reload();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_outlined,
                                      color: AppColors.danger),
                                  tooltip: '彻底删除',
                                  onPressed: () async {
                                    await DatabaseManager.instance.dao
                                        .purge(note.id);
                                    _reload();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
