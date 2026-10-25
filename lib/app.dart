import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/navigation/app_routes.dart';
import 'package:safemate/core/security/app_lock_controller.dart';
import 'package:safemate/core/security/auth_service.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/home/home_screen.dart';
import 'package:safemate/features/lock/lock_screen.dart';
import 'package:safemate/features/setup/setup_pin_screen.dart';

/// 根组件:三态路由(未配置 → 设置 / 已锁 → 解锁 / 已解锁 → 首页)
class SafeMateApp extends StatelessWidget {
  const SafeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MiuixApp(
      navigatorKey: AppRoutes.rootNavigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLockController.instance,
        AuthService.instance,
      ]),
      builder: (context, _) {
        final Widget target;
        if (!AuthService.instance.isConfigured) {
          target = const SetupPinScreen(key: ValueKey('setup'));
        } else if (AppLockController.instance.isLocked) {
          target = const LockScreen(key: ValueKey('lock'));
        } else {
          target = const HomeScreen(key: ValueKey('home'));
        }

        return AnimatedSwitcher(
          duration: AppMotion.slow,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: _springyTransition,
          child: target,
        );
      },
    );
  }

  Widget _springyTransition(Widget child, Animation<double> animation) {
    final scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: animation, curve: AppMotion.bounceIn),
    );
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}
