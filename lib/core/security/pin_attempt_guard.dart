import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/storage/secure_storage.dart';
import 'package:safemate/core/utils/log.dart';

/// 解锁限流器 —— 界面层暴力破解防线(PBKDF2 是计算层防线)
///
/// 升级冷却:5 次→30s;10 次→2min;15 次→15min;25 次→1h。
/// 12 小时无失败则计数自然衰减归零。
/// 伪装完整性优先:进入伪装空间也视为"解锁成功"并清零计数。
class PinAttemptGuard {
  PinAttemptGuard._();

  static final PinAttemptGuard instance = PinAttemptGuard._();

  static const List<int> _thresholds = [5, 10, 15, 25];
  static const List<Duration> _cooldowns = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];
  static const Duration _decayWindow = Duration(hours: 12);

  Future<Map<String, dynamic>> _readState() async =>
      await SecureStorageService.instance
          .readJson(AppConstants.stateBlobKey) ??
      <String, dynamic>{'f': 0, 't': 0};

  Future<void> _writeState(int fails, int lastFailAtMs) =>
      SecureStorageService.instance.writeJson(
        AppConstants.stateBlobKey,
        <String, dynamic>{'f': fails, 't': lastFailAtMs},
      );

  /// 当前剩余冷却;null 表示可立即尝试
  Future<Duration?> cooldownRemaining() async {
    final state = await _readState();
    final fails = state['f'] as int? ?? 0;
    final lastAt = DateTime.fromMillisecondsSinceEpoch(
      (state['t'] as int? ?? 0),
    );
    final cooldown = _cooldownFor(fails);
    if (cooldown == null) return null;
    final remaining = lastAt.add(cooldown).difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// 记录一次失败;返回新触发的冷却(未触发返回 null)
  Future<Duration?> registerFailure() async {
    final state = await _readState();
    var fails = state['f'] as int? ?? 0;
    final lastAt = DateTime.fromMillisecondsSinceEpoch(
      (state['t'] as int? ?? 0),
    );

    if (fails > 0 && DateTime.now().difference(lastAt) > _decayWindow) {
      fails = 0; // 衰减:超 12h 未失败,重新起算
    }

    fails += 1;
    await _writeState(fails, DateTime.now().millisecondsSinceEpoch);
    final triggered = _cooldownFor(fails);
    if (triggered != null) Log.d('[SafeMate] throttle engaged: fails=$fails');
    return triggered;
  }

  /// 解锁成功(真/伪空间均调用)→ 清零
  Future<void> registerSuccess() => _writeState(0, 0);

  Duration? _cooldownFor(int fails) {
    for (var i = _thresholds.length - 1; i >= 0; i--) {
      if (fails >= _thresholds[i]) return _cooldowns[i];
    }
    return null;
  }
}
