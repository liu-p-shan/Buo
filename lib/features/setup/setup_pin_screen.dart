import 'package:flutter/material.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/security/auth_service.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/shared/pin_pad.dart';

enum _SetupStage {
  intro,
  realFirst,
  realConfirm,
  decoyFirst,
  decoyConfirm,
  creating,
}

/// 首启引导:欢迎页 → 真 PIN → 伪装 PIN → 生成密钥
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  _SetupStage _stage = _SetupStage.intro;
  String _entry = '';
  String _realPin = '';
  String? _error;

  bool get _isConfirmStage =>
      _stage == _SetupStage.realConfirm || _stage == _SetupStage.decoyConfirm;
  bool get _isDecoyStage =>
      _stage == _SetupStage.decoyFirst || _stage == _SetupStage.decoyConfirm;

  void _digit(String d) {
    if (_entry.length >= AppConstants.pinMaxLength) return;
    setState(() {
      _entry += d;
      _error = null;
    });
  }

  void _next() {
    if (_entry.length < AppConstants.pinMinLength) {
      setState(() => _error = '至少 ${AppConstants.pinMinLength} 位数字');
      return;
    }
    switch (_stage) {
      case _SetupStage.intro:
        setState(() => _stage = _SetupStage.realFirst);
      case _SetupStage.realFirst:
        _realPin = _entry;
        setState(() {
          _stage = _SetupStage.realConfirm;
          _entry = '';
          _error = null;
        });
      case _SetupStage.realConfirm:
        if (_entry != _realPin) {
          setState(() {
            _error = '两次输入不一致,请重新设置';
            _entry = '';
          });
          return;
        }
        setState(() {
          _stage = _SetupStage.decoyFirst;
          _entry = '';
        });
      case _SetupStage.decoyFirst:
        setState(() {
          _stage = _SetupStage.decoyConfirm;
          _entry = '';
          _error = null;
        });
      case _SetupStage.decoyConfirm:
        _finish();
      case _SetupStage.creating:
        break;
    }
  }

  Future<void> _finish() async {
    if (_entry == _realPin) {
      setState(() {
        _error = '伪装密码不能与常用密码相同';
        _entry = '';
      });
      return;
    }
    setState(() => _stage = _SetupStage.creating);
    try {
      await AuthService.instance.setup(realPin: _realPin, decoyPin: _entry);
      // 成功后根路由自动切换到首页
    } on SetupException catch (e) {
      setState(() {
        _stage = _SetupStage.intro;
        _entry = '';
        _realPin = '';
        _error = '初始化失败(代码 ${e.code}),请把代码反馈给开发者';
      });
    } catch (e) {
      setState(() {
        _stage = _SetupStage.intro;
        _entry = '';
        _realPin = '';
        _error = '初始化失败(代码 E0),请把代码反馈给开发者';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ImmersiveStatusBar.dark(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: AppMotion.normal,
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: _buildStage(scheme),
          ),
        ),
      ),
    );
  }

  Widget _buildStage(ColorScheme scheme) {
    switch (_stage) {
      case _SetupStage.intro:
        return _IntroView(
          hadCorruption: AuthService.instance.hadCorruption,
          onStart: () => setState(() => _stage = _SetupStage.realFirst),
        );
      case _SetupStage.creating:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 20),
              Text('正在生成加密密钥…',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        );
      default:
        return _buildPinStage(scheme);
    }
  }

  Widget _buildPinStage(ColorScheme scheme) {
    final titles = {
      _SetupStage.realFirst: '设置常用密码',
      _SetupStage.realConfirm: '再次输入常用密码',
      _SetupStage.decoyFirst: '设置伪装密码',
      _SetupStage.decoyConfirm: '再次输入伪装密码',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isDecoyStage)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.companion.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '伪装密码用于不得不交出密码的特殊时刻:输入它将进入一个外观完全相同的普通笔记空间,真实笔记安然无恙。',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
            )
          else
            Text('这个密码用于日常解锁,请牢牢记住。',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          const Spacer(),
          Text(titles[_stage]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 36),
          ShakeWrap(
            nonce: (_error ?? '').length + _entry.length,
            child: PinDots(length: _entry.length, error: _error != null),
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? '${_entry.length}/${AppConstants.pinMaxLength} 位',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _error != null ? AppColors.danger : scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          PinPad(
            onDigit: _digit,
            onBackspace: () => setState(() {
              if (_entry.isNotEmpty) {
                _entry = _entry.substring(0, _entry.length - 1);
              }
              _error = null;
            }),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: _isConfirmStage ? '确认' : '继续',
            onPressed:
                _entry.length >= AppConstants.pinMinLength ? _next : null,
          ),
          TextButton(
            onPressed: _stage == _SetupStage.realConfirm
                ? () => setState(() {
                      _stage = _SetupStage.realFirst;
                      _entry = '';
                      _error = null;
                    })
                : null,
            child: const Text('重新输入'),
          ),
        ],
      ),
    );
  }
}

/// 欢迎页:Logo + 三大特性 + 开始按钮(产品级首屏)
class _IntroView extends StatelessWidget {
  const _IntroView({required this.hadCorruption, required this.onStart});

  final bool hadCorruption;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.companion],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.shield_outlined,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(AppConstants.appName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(AppConstants.appTagline,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            const _FeatureTile(
              icon: Icons.layers_outlined,
              color: AppColors.accent,
              title: '双空间保护',
              subtitle: '常用密码与伪装密码,各开一个独立加密空间',
            ),
            const SizedBox(height: 12),
            const _FeatureTile(
              icon: Icons.fingerprint,
              color: AppColors.companion,
              title: '指纹秒开',
              subtitle: '验证指纹直达真实笔记,切后台自动上锁',
            ),
            const SizedBox(height: 12),
            const _FeatureTile(
              icon: Icons.lock_outline,
              color: AppColors.success,
              title: '全程加密',
              subtitle: 'SQLCipher 本地加密,完全离线,数据不出设备',
            ),
            if (hadCorruption) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '检测到加密存储异常(通常由系统还原或换机引起),旧数据已无法恢复,初始化时将安全抹除残留文件。',
                  style: TextStyle(color: scheme.onSurface, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 32),
            _PrimaryButton(label: '开始使用', onPressed: onStart),
            const SizedBox(height: 12),
            Text(
              '下一步将为你的笔记设置两道密码',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: enabled
            ? AppColors.accent
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        elevation: enabled ? 2 : 0,
        shadowColor: AppColors.accent.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
