import 'package:flutter/services.dart';

import 'package:safemate/core/utils/log.dart';

/// FLAG_SECURE 防护(原生 MethodChannel,零第三方依赖):
/// 1. 最近任务预览为空白 —— 弥补生命周期锁与系统快照之间的竞态;
/// 2. 截屏与录屏被系统阻断。
/// 取舍:用户也无法截自己的笔记 —— 安全笔记类应用的标准选择。
abstract final class SecureWindow {
  static const MethodChannel _channel = MethodChannel('buo/security');

  static bool _enabled = false;
  static bool get isEnabled => _enabled;

  static Future<void> setEnabled(bool value) async {
    try {
      await _channel.invokeMethod<void>('setSecure', value);
      _enabled = value;
    } on MissingPluginException {
      Log.d('[SafeMate] secure-window unavailable on this platform');
    } on PlatformException {
      // 静默降级:防护失败不阻塞主流程
    }
  }
}
