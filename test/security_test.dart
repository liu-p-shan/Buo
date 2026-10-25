import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safemate/core/constants/safety_tips.dart';
import 'package:safemate/core/crypto/pin_hasher.dart';
import 'package:safemate/core/database/note_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PBKDF2-HMAC-SHA256 已知向量 c=1', () async {
    final dk = await PinHasher.pbkdf2(
      password: 'password',
      salt: utf8.encode('salt'),
      iterations: 1,
      keyLength: 32,
    );
    expect(
      hex.encode(dk),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
  });

  test('PBKDF2-HMAC-SHA256 已知向量 c=2', () async {
    final dk = await PinHasher.pbkdf2(
      password: 'password',
      salt: utf8.encode('salt'),
      iterations: 2,
      keyLength: 32,
    );
    expect(
      hex.encode(dk),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
  });

  test('常数时间比较', () {
    expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(PinHasher.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });

  test('每日贴士:当日确定 + 永远在池内', () {
    final day = DateTime(2026, 10, 24);
    expect(SafetyContent.tipOfTheDay(day), SafetyContent.tipOfTheDay(day));
    expect(SafetyContent.tips.contains(SafetyContent.tipOfTheDay(day)), isTrue);
  });

  test('LIKE 通配符转义', () {
    expect(NoteDao.escapeLike(r'a%b_c\d'), r'a\%b\_c\\d');
  });
}
