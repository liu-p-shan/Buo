import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:safemate/core/constants/app_constants.dart';

/// PIN 校验块:盐 + 摘要 + 迭代次数(随凭据块持久化)
class PinVerifyBlock {
  const PinVerifyBlock({
    required this.saltHex,
    required this.hashHex,
    required this.iterations,
  });

  final String saltHex;
  final String hashHex;
  final int iterations;

  Map<String, dynamic> toMap() => {
        'salt': saltHex,
        'hash': hashHex,
        'iters': iterations,
      };

  factory PinVerifyBlock.fromMap(Map<String, dynamic> map) => PinVerifyBlock(
        saltHex: map['salt'] as String,
        hashHex: map['hash'] as String,
        iterations: map['iters'] as int,
      );
}

/// 密码学随机字节(PIN 盐 / 数据库主密钥均由此生成)
abstract final class SecureBytes {
  static Uint8List generate(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

/// PBKDF2 计算参数(compute 跨 Isolate 传递,需为纯数据类)
class _Pbkdf2Args {
  const _Pbkdf2Args({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.keyLength,
  });

  final List<int> password; // PIN 为纯数字,codeUnits 即字节
  final List<int> salt;
  final int iterations;
  final int keyLength;
}

/// PIN 摘要器:PBKDF2-HMAC-SHA256(RFC 8018)
abstract final class PinHasher {
  /// 生成校验块(设置/修改 PIN 时)
  static Future<PinVerifyBlock> hashPin(String pin) async {
    final salt = SecureBytes.generate(AppConstants.saltLengthBytes);
    final derived = await pbkdf2(
      password: pin,
      salt: salt,
      iterations: AppConstants.pbkdf2Iterations,
      keyLength: AppConstants.derivedKeyLengthBytes,
    );
    return PinVerifyBlock(
      saltHex: hex.encode(salt),
      hashHex: hex.encode(derived),
      iterations: AppConstants.pbkdf2Iterations,
    );
  }

  /// 校验 PIN(解锁时;与存储盐重新派生后比对)
  static Future<bool> verifyPin(String pin, PinVerifyBlock block) async {
    final derived = await pbkdf2(
      password: pin,
      salt: hex.decode(block.saltHex),
      iterations: block.iterations,
      keyLength: block.hashHex.length ~/ 2,
    );
    return constantTimeEquals(
      derived,
      Uint8List.fromList(hex.decode(block.hashHex)),
    );
  }

  /// 公开 PBKDF2(内部复用 + 单元测试向量校验)
  static Future<Uint8List> pbkdf2({
    required String password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) =>
      compute(
        _pbkdf2Job,
        _Pbkdf2Args(
          password: password.codeUnits,
          salt: salt,
          iterations: iterations,
          keyLength: keyLength,
        ),
      );

  /// 常数时间比较:命中与否耗时一致
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2 核心实现(compute 要求顶层/静态函数)
Uint8List _pbkdf2Job(_Pbkdf2Args args) {
  final hmac = Hmac(sha256, args.password);
  final blockCount = (args.keyLength + 31) ~/ 32;
  final output = BytesBuilder();

  for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
    final saltWithCounter = Uint8List.fromList([
      ...args.salt,
      blockIndex >> 24,
      blockIndex >> 16,
      blockIndex >> 8,
      blockIndex,
    ]);

    var u = hmac.convert(saltWithCounter).bytes; // U1 = PRF(P, S || INT(i))
    final t = Uint8List.fromList(u);
    for (var round = 1; round < args.iterations; round++) {
      u = hmac.convert(u).bytes; // Uj = PRF(P, Uj-1)
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k]; // T = U1 ^ U2 ^ ... ^ Uc
      }
    }
    output.add(t);
  }
  return output.takeBytes();
}
