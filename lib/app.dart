import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/navigation/app_routes.dart';
import 'package:safemate/core/security/app_lock_controller.dart';
import 'package:safemate/core/security/auth_service.dart';
import 'package:safemate/core/theme/app_theme.dart';
import 'package:safemate/features/home/home_screen.dart';
import 'package:safemate/features/lock/lock_screen.dart';
import 'package:safemate/features/setup/setup_pin_screen.dart';

/// 根组件:HyperOS 配色(MiuixSystemTheme)+ 稳定的 Material 渲染
class SafeMateApp extends StatelessWidget {
  const SafeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MiuixSystemTheme(
      child: Builder(
        builder: (context) {
          final themeData = MiuixTheme.of(context);
          return MaterialApp(
            navigatorKey: AppRoutes.rootNavigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: themeData.brightness,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.accent,
                brightness: themeData.brightness,
              ),
            ),
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

/// 四态路由:启动中 → 设置(首启)/ 锁定 / 已解锁
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
        if (!AuthService.instance.bootstrapped) {
          target = const _BootSplash(key: ValueKey('boot'));
        } else if (!AuthService.instance.isConfigured) {
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

/// 启动瞬间的加载页(安全存储自检期间,通常 < 0.5s)
class _BootSplash extends StatelessWidget {
  const _BootSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AppLogo(size: 76),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// 应用 Logo(与桌面图标同源:青蓝线条盾牌)
class _AppLogo extends StatelessWidget {
  const _AppLogo({this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.companion],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.shield_outlined,
          size: size * 0.5, color: Colors.white),
    );
  }
}
