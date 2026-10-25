import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safemate/app.dart';
import 'package:safemate/core/security/app_lock_controller.dart';
import 'package:safemate/core/security/auth_service.dart';
import 'package:safemate/core/security/secure_window.dart';
import 'package:safemate/core/storage/secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _hardenErrorHandling();

  // ── 系统呈现:竖屏 + 沉浸式 Edge-to-Edge ──────────────────────
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // ── 先让 UI 上屏,再做安全初始化 ─────────────────────────────
  // 任何初始化异常都不会把用户卡死在启动画面
  runApp(const SafeMateApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await SecureStorageService.instance.warmUp();
      await AuthService.instance.load();
    } catch (e) {
      // fail-open:初始化异常也照常进入未配置/锁定态,绝不白屏
      debugPrint('[SafeMate] bootstrap error: ${e.runtimeType}');
    } finally {
      AppLockController.instance.initialize();
      SecureWindow.setEnabled(true);
    }
  });
}

/// release 下抑制堆栈外泄,但保留可见的出错提示(方便用户反馈问题)
void _hardenErrorHandling() {
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Material(
          color: Color(0xFFF7F7F7),
          child: Center(
            child: Text(
              '抱歉,应用遇到了问题\n请退出后重新打开',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF888888), fontSize: 14, height: 1.8),
            ),
          ),
        );
    FlutterError.onError = (details) {
      debugPrint('[SafeMate] flutter-error: ${details.exception.runtimeType}');
    };
  }
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[SafeMate] uncaught: ${error.runtimeType}');
    return true;
  };
}
