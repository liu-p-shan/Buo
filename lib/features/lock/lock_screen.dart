import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/security/auth_service.dart';
import 'package:safemate/core/security/pin_attempt_guard.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/shared/pin_pad.dart';

/// 解锁页:指纹 / PIN 双路由。
/// 真/伪空间解锁的表现(文案/动画/耗时)完全一致 —— 旁观者无从分辨。
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _busy = false;
  bool _error = false;
  int _errorNonce = 0;
  String _message = '';
  bool _bioAvailable = false;
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    _checkCooldown();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final ok = await AuthService.instance.isBiometricAvailable();
    if (!mounted) return;
    setState(() => _bioAvailable = ok);
    if (ok) {
      // 进入锁屏自动请求一次指纹
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _checkCooldown() async {
    final remaining = await PinAttemptGuard.instance.cooldownRemaining();
    if (!mounted || remaining == null) return;
    _startCooldownTicker(remaining);
  }

  void _digit(String d) {
    if (_pin.length >= AppConstants.pinMaxLength) return;
    setState(() {
      _pin += d;
      _error = false;
      _message = '';
    });
  }

  Future<void> _tryBiometric() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await AuthService.instance.authenticateWithBiometric();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) setState(() => _message = '使用密码或指纹解锁');
  }

  Future<void> _submit() async {
    if (_busy || _pin.length < AppConstants.pinMinLength) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    final outcome = await AuthService.instance.verifyAndUnlock(_pin);
    if (!mounted) return;
    switch (outcome.kind) {
      case UnlockResultKind.success:
        break; // 根路由弹性转场接管
      case UnlockResultKind.wrong:
        setState(() {
          _busy = false;
          _pin = '';
          _error = true;
          _errorNonce++;
          _message = outcome.cooldown == null
              ? '密码不正确'
              : '尝试次数过多,请 ${outcome.cooldown!.inSeconds + 1} 秒后再试';
        });
        if (outcome.cooldown != null) {
          _startCooldownTicker(outcome.cooldown!);
        }
      case UnlockResultKind.throttled:
        setState(() {
          _busy = false;
          _pin = '';
        });
        _startCooldownTicker(outcome.cooldown!);
    }
  }

  void _startCooldownTicker(Duration remaining) {
    var left = remaining;
    _cooldownTicker?.cancel();
    setState(() => _message = '请 ${left.inSeconds + 1} 秒后重试');
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      left = left - const Duration(seconds: 1);
      if (!mounted) return t.cancel();
      if (left.isNegative) {
        t.cancel();
        setState(() => _message = '');
      } else {
        setState(() => _message = '请 ${left.inSeconds + 1} 秒后重试');
      }
    });
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了,注意休息';
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cooling = _cooldownTicker != null;
    return MiuixScaffold(
      content: ImmersiveStatusBar.dark(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const _BreathingShield(),
                const SizedBox(height: 20),
                Text(_greeting,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                const Text(AppConstants.appName,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const Spacer(),
                ShakeWrap(
                  nonce: _errorNonce,
                  child: PinDots(length: _pin.length, error: _error),
                ),
                const SizedBox(height: 10),
                Text(
                  _message.isEmpty && _busy ? '验证中…' : _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        _error ? AppColors.danger : scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                PinPad(
                  enabled: !_busy && !cooling,
                  onDigit: _digit,
                  onBackspace: () => setState(() {
                    if (_pin.isNotEmpty) {
                      _pin = _pin.substring(0, _pin.length - 1);
                    }
                  }),
                  bottomLeft:
                      _bioAvailable ? _BioKey(onTap: _tryBiometric) : null,
                ),
                const SizedBox(height: 18),
                _UnlockButton(
                  enabled: !_busy &&
                      !cooling &&
                      _pin.length >= AppConstants.pinMinLength,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BioKey extends StatelessWidget {
  const _BioKey({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.45,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.fingerprint, size: 26, color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: const Text('解锁',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// 盾牌图标:2.4s 呼吸缩放,生命感
class _BreathingShield extends StatefulWidget {
  const _BreathingShield();

  @override
  State<_BreathingShield> createState() => _BreathingShieldState();
}

class _BreathingShieldState extends State<_BreathingShield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.06)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.companion],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child:
            const Icon(Icons.shield_outlined, size: 42, color: Colors.white),
      ),
    );
  }
}
