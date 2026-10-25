import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/navigation/app_routes.dart';
import 'package:safemate/core/security/app_lock_controller.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/home/trash_screen.dart';

Future<void> showMoreSheet(BuildContext context, {VoidCallback? onChanged}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
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
          _MoreAction(
            icon: Icons.delete_outline,
            label: '回收站',
            onTap: () async {
              Navigator.pop(sheetContext);
              await AppRoutes.pushSpring(context, const TrashScreen());
              onChanged?.call();
            },
          ),
          _MoreAction(
            icon: Icons.info_outline,
            label: '关于 Buo',
            onTap: () {
              Navigator.pop(sheetContext);
              AppRoutes.showSpringDialog(
                context,
                builder: (_) => const _AboutDialog(),
              );
            },
          ),
          _MoreAction(
            icon: Icons.lock_outline,
            label: '立即锁定',
            onTap: () {
              Navigator.pop(sheetContext);
              AppLockController.instance.lock(reason: 'manual-lock');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _MoreAction extends StatelessWidget {
  const _MoreAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: scheme.onSurface),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }
}

/// "关于"弹窗:版本 + 联系方式(QQ 一键复制)
class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 324,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          color: scheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.companion],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shield_outlined,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text(AppConstants.appName,
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(AppConstants.appTagline,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text('版本 ${AppConstants.appVersion} (${AppConstants.appBuild})',
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
              const SizedBox(height: 18),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 6),
              const _AboutRow(label: '开发者', value: AppConstants.contactName),
              const _QQRow(),
              const SizedBox(height: 8),
              Text(AppConstants.contactHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('我知道了',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
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

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QQRow extends StatefulWidget {
  const _QQRow();

  @override
  State<_QQRow> createState() => _QQRowState();
}

class _QQRowState extends State<_QQRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('QQ',
              style:
                  TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          const Spacer(),
          const Text(AppConstants.contactQQ,
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Material(
            color: _copied
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () async {
                await Clipboard.setData(
                    const ClipboardData(text: AppConstants.contactQQ));
                if (!mounted) return;
                setState(() => _copied = true);
                Future.delayed(const Duration(seconds: 2),
                    () => mounted ? setState(() => _copied = false) : null);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Text(_copied ? '已复制' : '复制',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            _copied ? AppColors.success : AppColors.accent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
