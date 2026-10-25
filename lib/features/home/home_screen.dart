import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart' as miuix;

import 'package:safemate/core/database/database_manager.dart';
import 'package:safemate/core/database/note_dao.dart';
import 'package:safemate/core/navigation/app_routes.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/editor/note_editor_screen.dart';
import 'package:safemate/features/home/more_sheet.dart';
import 'package:safemate/features/home/trash_screen.dart';
import 'package:safemate/features/home/widgets/companion_card.dart';
import 'package:safemate/features/home/widgets/note_card.dart';
import 'package:safemate/features/shared/spring_pressable.dart';

/// 笔记列表首页(真/伪空间共用同一 UI,行为零差异)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  String _keyword = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final notes = await DatabaseManager.instance.dao
        .listNotes(keyword: _keyword.isEmpty ? null : _keyword);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _openEditor([Note? note]) async {
    await AppRoutes.pushSpring(context, NoteEditorScreen(note: note));
    _reload();
  }

  Future<void> _noteActions(Note note) async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            _SheetAction(
              icon: note.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              label: note.pinned ? '取消置顶' : '置顶',
              onTap: () async {
                Navigator.pop(sheetContext);
                await DatabaseManager.instance.dao
                    .update(note.copyWith(pinned: !note.pinned));
                _reload();
              },
            ),
            _SheetAction(
              icon: Icons.delete_outline,
              label: '移入回收站',
              color: AppColors.danger,
              onTap: () async {
                Navigator.pop(sheetContext);
                await DatabaseManager.instance.dao.moveToTrash(note.id);
                _reload();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return miuix.Scaffold(
      body: ImmersiveStatusBar.dark(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              const Text('Buo',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              showMoreSheet(context, onChanged: _reload),
                          icon: Icon(Icons.more_horiz, color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: CompanionCard(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _keyword = v),
                      onSubmitted: (_) => _reload(),
                      onCleared: () {
                        _searchCtrl.clear();
                        setState(() => _keyword = '');
                        _reload();
                      },
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : _notes.isEmpty
                            ? const _EmptyState()
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 108),
                                itemCount: _notes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final note = _notes[i];
                                  return NoteCard(
                                    note: note,
                                    onTap: () => _openEditor(note),
                                    onLongPress: () => _noteActions(note),
                                  );
                                },
                              ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 28,
                child: SpringPressable(
                  onTap: () => _openEditor(),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, Color(0xFF1F6FE0)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: tint),
      title: Text(label, style: TextStyle(fontSize: 15, color: tint)),
      onTap: onTap,
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '搜索笔记',
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.cancel, size: 18, color: scheme.outline),
              onPressed: onCleared,
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 56, color: scheme.outlineVariant),
          const SizedBox(height: 14),
          Text('还没有笔记',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.outline)),
          const SizedBox(height: 4),
          Text('点右下角的加号,写下第一条',
              style: TextStyle(fontSize: 13, color: scheme.outline)),
        ],
      ),
    );
  }
}
