/// 陪伴内容池:每日安全贴士 + 鼓励语
abstract final class SafetyContent {
  static const List<String> tips = [
    '给重要账号开启两步验证,一道锁变两道锁。',
    '公共 Wi-Fi 下不登录支付类应用,必要时用移动数据。',
    '不同网站使用不同密码,一处泄露不殃及全局。',
    '收到"中奖""退款"短信,先通过官方渠道核实,别点链接。',
    '手机系统提示更新时尽早安装,补丁往往修复已知漏洞。',
    '社交平台的定位和行程,晒图前想一想要不要让陌生人看见。',
    '陌生二维码不乱扫,扫码前确认来源可信。',
    '旧手机转手前,务必退出账号并恢复出厂设置。',
    '重要照片和文件定期备份到可信的加密存储。',
    '锁屏密码避免用生日和连续数字,长一点的口令更安全。',
    '应用只从官方应用商店下载,警惕"高速下载器"。',
    '遇到转账请求,先打电话向本人确认,视频也可以被伪造。',
  ];

  static const List<String> encouragements = [
    '今天也平安度过了,你做得很棒。',
    '把担心写下来,它就变小了一点。',
    '深呼吸三次,大部分焦虑都会跟着呼气离开。',
    '你的每一笔记录,都是在认真照顾自己。',
    '慢慢来,安全感是一点一点攒出来的。',
    '有我在,你的秘密很安全。',
    '记得给今天的自己一句表扬。',
    '累了就休息,笔记和我都会等你。',
  ];

  static const String companionAlwaysHere = '无论遇到什么,小助手都会一直陪着你';

  /// 每日贴士:按本地日期确定性轮换(当天内稳定,隔天自然更换)
  static String tipOfTheDay([DateTime? now]) {
    final date = (now ?? DateTime.now());
    final dayIndex =
        date.difference(DateTime(date.year)).inDays + date.year * 366;
    return tips[dayIndex % tips.length];
  }

  static String randomTip() =>
      tips[DateTime.now().microsecondsSinceEpoch % tips.length];

  static String randomEncouragement() => encouragements[
      DateTime.now().microsecondsSinceEpoch % encouragements.length];
}
