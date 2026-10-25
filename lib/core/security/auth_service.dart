import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/crypto/pin_hasher.dart';
import 'package:safemate/core/database/database_manager.dart';
import 'package:safemate/core/security/app_lock_controller.dart';
import 'package:safemate/core/security/pin_attempt_guard.dart';
import 'package:safemate/core/storage/secure_storage.dart';
import 'package:safemate/core/utils/log.dart';

enum UnlockResultKind { success, wrong, throttled }

class UnlockOutcome {
  const UnlockOutcome._(this.kind, this.cooldown);

  factory UnlockOutcome.success() =>
      const UnlockOutcome._(UnlockResultKind.success, null);
  factory UnlockOutcome.wrong(Duration? triggeredCooldown) =>
      UnlockOutcome._(UnlockResultKind.wrong, triggeredCooldown);
  factory UnlockOutcome.throttled(Duration remaining) =>
      UnlockOutcome._(UnlockResultKind.throttled, remaining);

  final UnlockResultKind kind;
  final Duration? cooldown;
}

/// 单空间凭据(校验块 + 库主密钥 + 槽位文件)
class _VaultCred {
  const _VaultCred(this.pin, this.dbKeyHex, this.fileName);

  final PinVerifyBlock pin;
  final String dbKeyHex;
  final String fileName;

  Map<String, dynamic> toJson() => {
        'pin': pin.toMap(),
        'dbKey': dbKeyHex,
        'slot': fileName,
      };

  static _VaultCred fromJson(Map<String, dynamic> map) => _VaultCred(
        PinVerifyBlock.fromMap(map['pin'] as Map<String, dynamic>),
        map['dbKey'] as String,
        map['slot'] as String,
      );
}

/// 凭据块:{v0:{...}, v1:{...}, r:0|1}
class _CredBlob {
  const _CredBlob(this.a, this.b, this.realIndex);

  final _VaultCred a; // 槽位 vault_a.db
  final _VaultCred b; // 槽位 vault_b.db
  final int realIndex; // 0 → a 为真库;1 → b 为真库

  _VaultCred get real => realIndex == 0 ? a : b;
  _VaultCred get decoy => realIndex == 0 ? b : a;

  Map<String, dynamic> toJson() =>
      {'v0': a.toJson(), 'v1': b.toJson(), 'r': realIndex};

  static _CredBlob fromJson(Map<String, dynamic> map) => _CredBlob(
        _VaultCred.fromJson(map['v0'] as Map<String, dynamic>),
        _VaultCred.fromJson(map['v1'] as Map<String, dynamic>),
        map['r'] as int,
      );
}

/// 初始化失败(带阶段代码与异常详情,便于远程定位)
class SetupException implements Exception {
  const SetupException(this.code, this.detail);

  final String code;
  final String detail;

  @override
  String toString() => 'SetupException($code/$detail)';
}

String _errText(Object e) {
  final s = e.toString();
  return s.length > 160 ? '${s.substring(0, 160)}…' : s;
}

/// 鉴权中枢:双 PIN 鉴别路由 / 指纹 → 真库 / 首启编排 / 损坏自愈
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  _CredBlob? _cred;
  VaultSpace? _activeSpace;
  bool _configured = false;
  bool _bootstrapped = false;

  bool get isConfigured => _configured;
  bool get bootstrapped => _bootstrapped;
  bool get hadCorruption => SecureStorageService.instance.corruptionDetected;
  VaultSpace get activeSpace => _activeSpace ?? VaultSpace.real;

  /// 启动加载:读取凭据块;任何异常都收敛到"未配置/已就绪",绝不卡启动页
  Future<void> load() async {
    try {
      try {
        final json = await SecureStorageService.instance
            .readJson(AppConstants.credBlobKey);
        _cred = json == null ? null : _CredBlob.fromJson(json);
        _configured = _cred != null;
      } on SecureStorageCorruptedException {
        _cred = null;
        _configured = false;
        Log.d('[SafeMate] cred blob unreadable → reset flow');
      }
    } catch (e) {
      _cred = null;
      _configured = false;
      Log.d('[SafeMate] load failed: ${e.runtimeType}');
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  /// 首启/重置:随机槽位绑定 + 双密钥生成 + 双 PIN 摘要 + 伪装库预置内容
  /// 每阶段带错误代码;失败时回滚到干净状态,绝不留半初始化
  Future<void> setup({
    required String realPin,
    required String decoyPin,
  }) async {
    if (hadCorruption) {
      try {
        await DatabaseManager.wipeAllFiles();
      } catch (_) {}
    }

    final realIndex = SecureBytes.generate(1)[0] & 1;

    _CredBlob blob;
    try {
      blob = _CredBlob(
        _VaultCred(
          await PinHasher.hashPin(realIndex == 0 ? realPin : decoyPin),
          bytesToHex(SecureBytes.generate(32)),
          AppConstants.vaultSlotA,
        ),
        _VaultCred(
          await PinHasher.hashPin(realIndex == 0 ? decoyPin : realPin),
          bytesToHex(SecureBytes.generate(32)),
          AppConstants.vaultSlotB,
        ),
        realIndex,
      );
    } catch (e) {
      throw SetupException('E1', _errText(e));
    }

    try {
      await SecureStorageService.instance
          .writeJson(AppConstants.credBlobKey, blob.toJson());
    } catch (e) {
      throw SetupException('E2', _errText(e));
    }
    _cred = blob;
    _configured = true;

    try {
      // 伪装库预置日常内容(空库一眼假)
      final decoyDao = await DatabaseManager.instance.open(
        VaultSpace.decoy,
        dbKeyHex: blob.decoy.dbKeyHex,
        fileName: blob.decoy.fileName,
        allowOrphanReset: true,
      );
      for (final seed in _decoySeeds) {
        await decoyDao.create(title: seed.$1, content: seed.$2);
      }
      // 打开真库
      await DatabaseManager.instance.open(
        VaultSpace.real,
        dbKeyHex: blob.real.dbKeyHex,
        fileName: blob.real.fileName,
        allowOrphanReset: true,
      );
    } catch (e) {
      // 回滚:清凭据 + 抹库文件,回到可重试的干净状态
      _cred = null;
      _configured = false;
      try {
        await DatabaseManager.instance.closeAll();
        await SecureStorageService.instance.delete(AppConstants.credBlobKey);
        await DatabaseManager.wipeAllFiles();
      } catch (_) {}
      throw SetupException('E3', _errText(e));
    }

    _activeSpace = VaultSpace.real;
    AppLockController.instance.unlock();
    notifyListeners();
  }

  static const List<(String, String)> _decoySeeds = [
    ('购物清单', '牛奶、鸡蛋、洗衣液,周末买点水果。'),
    ('周末计划', '周六上午跑步,下午整理房间;周日和朋友聚餐。'),
    ('常用信息', '快递地址写在手机备忘;燃气费每月15号前缴纳。'),
  ];

  /// PIN 解锁:恒定工作量(双空间并行校验,无论命中与否),
  /// 从时序上无法分辨进入的是哪个空间。
  Future<UnlockOutcome> verifyAndUnlock(String pin) async {
    final cooldown = await PinAttemptGuard.instance.cooldownRemaining();
    if (cooldown != null) return UnlockOutcome.throttled(cooldown);

    final cred = _cred;
    if (cred == null) return UnlockOutcome.wrong(null);

    final results = await Future.wait([
      PinHasher.verifyPin(pin, cred.real.pin),
      PinHasher.verifyPin(pin, cred.decoy.pin),
    ]);
    final realOk = results[0];
    final decoyOk = results[1];

    if (!realOk && !decoyOk) {
      final triggered = await PinAttemptGuard.instance.registerFailure();
      return UnlockOutcome.wrong(triggered);
    }

    await PinAttemptGuard.instance.registerSuccess();
    final target = realOk ? VaultSpace.real : VaultSpace.decoy;
    final vaultCred = realOk ? cred.real : cred.decoy;

    await DatabaseManager.instance.open(
      target,
      dbKeyHex: vaultCred.dbKeyHex,
      fileName: vaultCred.fileName,
    );
    _activeSpace = target;
    AppLockController.instance.unlock(); // 真/伪进入表现完全一致
    return UnlockOutcome.success();
  }

  // ── 生物识别:固定进真库 ─────────────────────────────────────

  Future<bool> isBiometricAvailable() async {
    try {
      final can = await _localAuth.canCheckBiometrics;
      if (!can || !await _localAuth.isDeviceSupported()) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    final cred = _cred;
    if (cred == null) return false;

    final controller = AppLockController.instance;
    controller.suppressAutoLock(true); // 指纹框期间抑制误锁(含补锁队列)
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: '验证指纹以解锁你的笔记',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return false;

      await PinAttemptGuard.instance.registerSuccess();
      await DatabaseManager.instance.open(
        VaultSpace.real,
        dbKeyHex: cred.real.dbKeyHex,
        fileName: cred.real.fileName,
      );
      _activeSpace = VaultSpace.real;
      controller.unlock();
      return true;
    } catch (e) {
      Log.d('[SafeMate] biometric failed: ${e.runtimeType}');
      return false;
    } finally {
      controller.suppressAutoLock(false);
    }
  }
}
