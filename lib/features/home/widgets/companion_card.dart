import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:safemate/core/constants/safety_tips.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/home/widgets/encouragement_dialog.dart';

/// 安全陪伴助手卡片:每日贴士 + Q弹头像
class CompanionCard extends StatefulWidget {
  const CompanionCard({super.key});

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard> {
  late String _tip = SafetyContent.tipOfTheDay();

  void _shuffle() => setState(() => _tip = SafetyContent.randomTip());

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.bounceIn,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(
          scale: 0.94 + 0.06 * t,
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFA640), Color(0xFFFF7E4C)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9455).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CompanionAvatar(
              size: 58,
              onTap: () => showEncouragementDialog(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('安全陪伴助手',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(width: 8),
                      _OnlineBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: AppMotion.bounceIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _tip,
                      key: ValueKey(_tip),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _shuffle,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: Text('换一条',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.white),
          SizedBox(width: 4),
          Text('陪伴中', style: TextStyle(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }
}

/// 陪伴头像:自绘笑脸(跨设备一致,不依赖 emoji 字体)
/// 按下快速压缩,松手 elasticOut 回弹 —— Q弹手感的本体
class CompanionAvatar extends StatefulWidget {
  const CompanionAvatar({super.key, required this.size, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  State<CompanionAvatar> createState() => _CompanionAvatarState();
}

class _CompanionAvatarState extends State<CompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.78).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.elasticOut,
  ));

  Future<void> _tap() async {
    if (_controller.isAnimating) return;
    _controller.duration = const Duration(milliseconds: 110);
    await _controller.forward();
    _controller.duration = const Duration(milliseconds: 700);
    await _controller.reverse();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _FacePainter(),
            size: Size.square(widget.size),
          ),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFA640));

    final dark = Paint()
      ..color = const Color(0xFF5B3A12)
      ..strokeWidth = size.width * 0.045
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final eyeY = c.dy - r * 0.28;
    canvas.drawCircle(Offset(c.dx - r * 0.38, eyeY), size.width * 0.032,
        Paint()..color = const Color(0xFF5B3A12));
    canvas.drawCircle(Offset(c.dx + r * 0.38, eyeY), size.width * 0.032,
        Paint()..color = const Color(0xFF5B3A12));

    final smile = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.18),
          width: r * 1.15,
          height: r * 1.05,
        ),
        0.25,
        math.pi * 0.5,
      );
    canvas.drawPath(smile, dark);

    // 腮红
    canvas.drawCircle(
      Offset(c.dx - r * 0.62, c.dy + r * 0.12),
      size.width * 0.045,
      Paint()..color = const Color(0xFFFFC9A3),
    );
    canvas.drawCircle(
      Offset(c.dx + r * 0.62, c.dy + r * 0.12),
      size.width * 0.045,
      Paint()..color = const Color(0xFFFFC9A3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
