import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:safemate/core/navigation/app_routes.dart';
import 'package:safemate/core/utils/log.dart';

typedef LockHook = Future<void> Function();

/// 全局锁定控制器 —— 生命周期安全中枢
///
/// 1. `inactive` 不锁(权限/指纹弹窗仅触发 inactive,避免死循环);
/// 2. `hidden`/`paused` 立即锁(覆盖最近任务预览窗口);
/// 3. 指纹弹窗期间进入待锁队列,抑制解除即补锁 —— 堵死绕过口;
/// 4. 锁定钩子与数据库解耦(DatabaseManager 注册 closeAll)。
class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController._internal();

  static final AppLockController instance = AppLockController._internal();

  bool _locked = true;
  bool _suppressAutoLock = false;
  bool _pendingLock = false;
  final List<LockHook> _lockHooks = [];

  bool get isLocked => _locked;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    Log.d('[SafeMate] lifecycle watchdog armed.');
  }

  void registerLockHook(LockHook hook) => _lockHooks.add(hook);

  /// 指纹等系统弹窗期间由 AuthService 维护;
  /// 置回 false 时,期间积压的后台事件立即补锁。
  void suppressAutoLock(bool value) {
    _suppressAutoLock = value;
    if (!value && _pendingLock) {
      _pendingLock = false;
      lock(reason: 'pending-background');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_suppressAutoLock) {
          _pendingLock = true;
        } else {
          lock(reason: 'app-backgrounded');
        }
      case AppLifecycleState.detached:
        lock(reason: 'app-detached');
      case AppLifecycleState.resumed:
        if (_pendingLock && !_suppressAutoLock) {
          _pendingLock = false;
          lock(reason: 'pending-background');
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// 锁定:先切 UI 回解锁页并弹回根路由,再回收敏感资源(关库)
  Future<void> lock({String reason = 'manual'}) async {
    if (_locked) return;
    _locked = true;
    Log.d('[SafeMate] locked ($reason)');
    notifyListeners();
    AppRoutes.popToRoot(); // 二级页面必须弹回,否则锁屏被盖住
    for (final hook in _lockHooks) {
      await hook();
    }
  }

  void unlock() {
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }
}
