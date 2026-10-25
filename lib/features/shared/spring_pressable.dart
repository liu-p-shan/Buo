import 'package:flutter/material.dart';

import 'package:safemate/core/theme/app_theme.dart';

/// 按压弹性容器:按下快速缩小,松手 elasticOut 回弹(Q弹手感)
class SpringPressable extends StatefulWidget {
  const SpringPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressScale = 0.94,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressScale;

  @override
  State<SpringPressable> createState() => _SpringPressableState();
}

class _SpringPressableState extends State<SpringPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.pressScale,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.elasticOut,
  ));

  bool _pressed = false;

  Future<void> _handleTap() async {
    if (_pressed) return;
    _pressed = true;
    _controller.duration = const Duration(milliseconds: 120);
    await _controller.forward();
    _controller.duration = const Duration(milliseconds: 650);
    await _controller.reverse();
    _pressed = false;
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
