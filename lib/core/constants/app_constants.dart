/// 全局常量
///
/// 取证对抗设计:
/// 1. 存储键名无语义(sm.cred.v1 / sm.state.v1),不暴露双空间结构;
/// 2. 两个数据库文件名完全对称(vault_a / vault_b),
///    真库落在哪个槽位由首启随机分配,文件层面无法分辨主次。
abstract final class AppConstants {
  // ── 应用信息 ────────────────────────────────────────────────
  static const String appName = 'Buo';
  static const String appTagline = '安全陪伴笔记';
  static const String appVersion = '1.0.3';
  static const String appBuild = '4';
  static const String contactName = '李明';
  static const String contactQQ = '2731379078';
  static const String contactHint = '遇到问题随时加QQ联系';

  // ── 安全存储键(内容均为加密 JSON Blob)───────────────────────
  static const String credBlobKey = 'sm.cred.v1';
  static const String stateBlobKey = 'sm.state.v1';

  // ── 数据库槽位(真/伪随机分配)────────────────────────────────
  static const String vaultSlotA = 'vault_a.db';
  static const String vaultSlotB = 'vault_b.db';

  // ── PIN 策略 ─────────────────────────────────────────────────
  static const int pinMinLength = 4;
  static const int pinMaxLength = 8;

  // ── PBKDF2-HMAC-SHA256 参数 ─────────────────────────────────
  static const int pbkdf2Iterations = 300000;
  static const int saltLengthBytes = 16;
  static const int derivedKeyLengthBytes = 32;
}
