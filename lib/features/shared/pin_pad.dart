import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/theme/app_theme.dart';

/// PIN 圆点指示(固定 pinMaxLength 格,已输入高亮,出错整排变红)
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    this.error = false,
  });

  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < AppConstants.pinMaxLength; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: i < length ? 14 : 10,
            height: i < length ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error
                  ? AppColors.danger
                  : (i < length ? AppColors.accent : scheme.outlineVariant),
            ),
          ),
        ],
      ],
    );
  }
}

/// 错误抖动容器(每次 nonce 变化触发一次)
class ShakeWrap extends StatelessWidget {
  const ShakeWrap({super.key, required this.nonce, required this.child});

  final int nonce;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(nonce),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (_, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 4) * 10 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}

/// 定制数字键盘(HyperOS 风格圆形按键,底部左侧可放自定义按键)
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.bottomLeft,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final Widget? bottomLeft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget key(String digit) => _PadKey(
          child: Text(digit,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          onTap: () => onDigit(digit),
        );

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 18),
                      Expanded(child: key(row[i])),
                    ],
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child:
                      bottomLeft ?? const SizedBox(height: 64), // 无自定义则占位
                ),
                const SizedBox(width: 18),
                Expanded(child: key('0')),
                const SizedBox(width: 18),
                Expanded(
                  child: _PadKey(
                    child: Icon(Icons.backspace_outlined,
                        size: 24, color: scheme.onSurface),
                    onTap: onBackspace,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.child, required this.onTap});

  final Widget child;
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
        child: InkWell(onTap: onTap, child: Center(child: child)),
      ),
    );
  }
}
