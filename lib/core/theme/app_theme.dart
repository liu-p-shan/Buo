import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ── Buo 品牌色板(HyperOS 质感)─────────────────────────────
abstract final class AppColors {
  /// 主强调色:HyperOS 蓝
  static const Color accent = Color(0xFF3D7FFF);

  /// 陪伴助手暖橙(头像 / 鼓励弹窗 / 贴士卡)
  static const Color companion = Color(0xFFFFA640);

  /// 危险操作 / 删除
  static const Color danger = Color(0xFFE5484D);

  /// 成功反馈
  static const Color success = Color(0xFF30A46C);
}

/// ── 动效口径(全 App 统一)───────────────────────────────────
abstract final class AppMotion {
  /// 入场回弹:Q弹(HyperOS 卡片弹出质感)
  static const Curve bounceIn = Curves.easeOutBack;

  /// 页面常规转场:先快后缓
  static const Curve pageTransition = Curves.easeOutCubic;

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
}

/// ── 沉浸式状态栏 ───────────────────────────────────────────────
/// 透明状态栏 + 底部导航栏,图标明暗随页面背景自适应。
///
/// 用法:包在每个页面最外层。
/// - 浅色背景页 → [ImmersiveStatusBar.dark](深色图标)
/// - 深色背景页 → [ImmersiveStatusBar.light](白色图标)
class ImmersiveStatusBar extends StatelessWidget {
  const ImmersiveStatusBar.dark({super.key, required this.child})
      : _iconBrightness = Brightness.dark;

  const ImmersiveStatusBar.light({super.key, required this.child})
      : _iconBrightness = Brightness.light;

  final Brightness _iconBrightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _iconBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: _iconBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
        // iOS:此字段表示"背景明暗",语义与图标相反
        statusBarBrightness:
            _iconBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}
