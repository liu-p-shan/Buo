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

  // ── 安全服务预热 ──────────────────────────────────────────────
  await SecureStorageService.instance.warmUp();
  await AuthService.instance.load();
  AppLockController.instance.initialize();

  runApp(const SafeMateApp());

  // ── 首帧后开启 FLAG_SECURE:防截屏 + 任务栈预览空白 ───────────
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SecureWindow.setEnabled(true);
  });
}

/// release 下抑制错误详情外泄(堆栈可能暴露文件路径/数据结构)
void _hardenErrorHandling() {
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const SizedBox.shrink();
    FlutterError.onError = (details) {
      debugPrint('[SafeMate] flutter-error: ${details.exception.runtimeType}');
    };
  }
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[SafeMate] uncaught: ${error.runtimeType}');
    return true;
  };
}
