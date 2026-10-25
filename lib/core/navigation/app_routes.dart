import 'package:flutter/material.dart';

import 'package:safemate/core/theme/app_theme.dart';

/// 全局导航:弹簧转场路由 / 弹簧弹窗 / 根导航键
class AppRoutes {
  AppRoutes._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// 锁定时弹回根路由(配合 AppLockController.lock)
  static void popToRoot() =>
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);

  static Future<T?> pushSpring<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(SpringPageRoute<T>(page: page));

  /// 弹簧缩放弹窗(easeOutBack,HyperOS 卡片弹出质感)
  static Future<T?> showSpringDialog<T>(
    BuildContext context,
    WidgetBuilder builder, {
    bool dismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black38,
      transitionDuration: AppMotion.normal,
      pageBuilder: (context, _, __) => builder(context),
      transitionBuilder: (context, animation, _, child) {
        final scale = Tween<double>(begin: 0.85, end: 1).animate(
          CurvedAnimation(parent: animation, curve: AppMotion.bounceIn),
        );
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}

/// 页面转场:轻上滑 + 回弹缩放
class SpringPageRoute<T> extends PageRouteBuilder<T> {
  SpringPageRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, _, child) {
            final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.045),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            final scale = Tween<double>(begin: 0.97, end: 1).animate(
              CurvedAnimation(parent: animation, curve: AppMotion.bounceIn),
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
        );
}
