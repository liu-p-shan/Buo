import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart' as miuix;

import 'package:safemate/core/database/database_manager.dart';
import 'package:safemate/core/database/note_dao.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/home/widgets/note_card.dart';

/// 笔记编辑器(新建/编辑共用)
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late int _color;
  late bool _pinned;
  bool _saving = false;

  bool get _isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _title = TextEditingController(text: note?.title ?? '');
    _content = TextEditingController(text: note?.content ?? '');
    _color = note?.color ?? 0;
    _pinned = note?.pinned ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty && content.isEmpty) {
      Navigator.of(context).pop(); // 空笔记直接返回,不留垃圾数据
      return;
    }
    setState(() => _saving = true);
    final dao = DatabaseManager.instance.dao;
    final note = widget.note;
    if (note == null) {
      await dao.create(
          title: title, content: content, color: _color, pinned: _pinned);
    } else {
      await dao.update(note.copyWith(
        title: title,
        content: content,
        color: _color,
        pinned: _pinned,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final note = widget.note;
    if (note == null) return;
    await DatabaseManager.instance.dao.moveToTrash(note.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return miuix.Scaffold(
      appBar: miuix.AppBar(
        title: Text(_isNew ? '新建笔记' : '编辑笔记'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '移入回收站',
              onPressed: _delete,
            ),
        ],
      ),
      body: ImmersiveStatusBar.dark(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  controller: _title,
                  autofocus: _isNew,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '标题',
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _content,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '写点什么…',
                      hintStyle: TextStyle(color: scheme.outline),
                    ),
                  ),
                ),
              ),
              _EditorBottomBar(
                selectedColor: _color,
                pinned: _pinned,
                saving: _saving,
                onSelectColor: (i) => setState(() => _color = i),
                onTogglePinned: () => setState(() => _pinned = !_pinned),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorBottomBar extends StatelessWidget {
  const _EditorBottomBar({
    required this.selectedColor,
    required this.pinned,
    required this.saving,
    required this.onSelectColor,
    required this.onTogglePinned,
    required this.onSave,
  });

  final int selectedColor;
  final bool pinned;
  final bool saving;
  final ValueChanged<int> onSelectColor;
  final VoidCallback onTogglePinned;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
            top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < NoteCard.palette.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => onSelectColor(i),
                    child: AnimatedScale(
                      scale: selectedColor == i ? 1.25 : 1,
                      duration: AppMotion.normal,
                      curve: AppMotion.bounceIn, // 选中回弹
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: NoteCard.palette[i],
                          border: selectedColor == i
                              ? Border.all(color: scheme.onSurface, width: 2)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pinned ? 1 : 0),
            duration: AppMotion.normal,
            curve: AppMotion.bounceIn,
            builder: (_, t, child) =>
                Transform.rotate(angle: t * 0.5, child: child!),
            child: IconButton(
              icon: Icon(
                pinned ? Icons.star : Icons.star_border,
                color: pinned ? AppColors.companion : scheme.outline,
              ),
              tooltip: pinned ? '取消置顶' : '置顶',
              onPressed: onTogglePinned,
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: saving ? null : onSave,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('保存',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
