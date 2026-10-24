import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'db_helper.dart';

enum UnlockSpace { real, decoy }

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const String _keyDbPassword = 'sm.cred.v1';
  static const String _keyDecoyDbPassword = 'sm.cred.v2';
  static const String _keyPinSalt = 'sm.state.v1';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _localAuth = LocalAuthentication();
  UnlockSpace? currentSpace;

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<String> _getOrCreateKey(String storageKey) async {
    String? key = await _storage.read(key: storageKey);
    if (key == null || key.length != 64) {
      key = DbHelper.generateHexKey();
      await _storage.write(key: storageKey, value: key);
    }
    return key;
  }

  Future<String> _hashPin(String pin) async {
    String? salt = await _storage.read(key: _keyPinSalt);
    if (salt == null) {
      salt = List<int>.generate(16, (_) => Random.secure().nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _keyPinSalt, value: salt);
    }
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  Future<bool> hasPin() async => (await _storage.read(key: 'sm.pin.v1')) != null;
  Future<bool> hasDecoyPin() async => (await _storage.read(key: 'sm.pin.v2')) != null;

  Future<void> setRealPin(String pin) async => await _storage.write(key: 'sm.pin.v1', value: await _hashPin(pin));
  Future<void> setDecoyPin(String pin) async => await _storage.write(key: 'sm.pin.v2', value: await _hashPin(pin));

  Future<String?> unlockWithBiometric() async {
    if (!await isBiometricAvailable()) return 'No biometrics';
    bool auth = false;
    try {
      auth = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to unlock notes',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (e) { return 'Error: $e'; }
    if (!auth) return 'Cancelled';
    return _unlockSpace(UnlockSpace.real);
  }

  Future<String?> unlockWithPin(String pin) async {
    final hash = await _hashPin(pin);
    if (hash == await _storage.read(key: 'sm.pin.v1')) return _unlockSpace(UnlockSpace.real);
    if (hash == await _storage.read(key: 'sm.pin.v2')) return _unlockSpace(UnlockSpace.decoy);
    return 'Wrong PIN';
  }

  Future<String?> _unlockSpace(UnlockSpace space) async {
    try {
      if (space == UnlockSpace.real) {
        await DbHelper.instance.open(await _getOrCreateKey(_keyDbPassword), dbName: DbHelper.dbNameReal);
      } else {
        await DbHelper.instance.open(await _getOrCreateKey(_keyDecoyDbPassword), dbName: DbHelper.dbNameDecoy);
      }
      currentSpace = space;
      return null;
    } catch (e) { return 'DB Error: $e'; }
  }

  Future<void> lock() async {
    await DbHelper.instance.close();
    currentSpace = null;
  }
}
