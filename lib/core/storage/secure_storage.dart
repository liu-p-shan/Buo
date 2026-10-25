import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:safemate/core/constants/app_constants.dart';
import 'package:safemate/core/utils/log.dart';

/// 安全存储层损坏(典型场景:系统备份还原到新设备后 AndroidKeyStore
/// 主密钥丢失,EncryptedSharedPreferences 无法解密)。
/// 上层(AuthService)捕获后进入"带警示的重置流程"。
class SecureStorageCorruptedException implements Exception {
  const SecureStorageCorruptedException(this.platformCode);

  final String platformCode;

  @override
  String toString() => 'SecureStorageCorruptedException($platformCode)';
}

/// flutter_secure_storage 唯一封装
///
/// - Android:EncryptedSharedPreferences(AES-256-GCM,密钥存于
///   AndroidKeyStore,硬件安全模块可用时不可导出);
/// - 任何存储层 PlatformException 一律按"损坏"处理 —— 故障关闭:
///   宁可进入重置流程,不让用户带着异常状态继续用。
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  /// warmUp 探测阶段是否已检出损坏(供重置流程展示警示)
  bool corruptionDetected = false;

  /// 启动自检:实际读一次凭据键,触发 ESP 初始化并暴露潜在损坏
  Future<void> warmUp() async {
    try {
      await read(AppConstants.credBlobKey);
    } on SecureStorageCorruptedException {
      corruptionDetected = true;
      Log.d('[SafeMate] secure storage corrupted (keyset lost?)');
    }
  }

  Future<String?> read(String key) => _guard(() => _storage.read(key: key));

  Future<void> write(String key, String value) =>
      _guard(() => _storage.write(key: key, value: value));

  Future<void> delete(String key) => _guard(() => _storage.delete(key: key));

  Future<void> deleteAll() => _guard(() => _storage.deleteAll());

  // ── JSON Blob 便捷层 ──────────────────────────────────────────

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeJson(String key, Map<String, dynamic> data) =>
      write(key, jsonEncode(data));

  /// 统一异常转换:存储层异常 → 强类型损坏异常
  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PlatformException catch (e) {
      Log.d('[SafeMate] secure-storage failure: ${e.code}');
      throw SecureStorageCorruptedException(e.code);
    }
  }
}
