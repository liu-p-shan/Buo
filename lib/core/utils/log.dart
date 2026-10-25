import 'package:flutter/foundation.dart';

/// 统一日志出口:Release 构建完全静默。
/// 上架产品严禁在 logcat 泄露安全行为(锁定原因/解锁事件等)。
abstract final class Log {
  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
