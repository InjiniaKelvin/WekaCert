import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';

import 'preferences_service.dart';

class AuthService {
  AuthService(this._preferences);

  final PreferencesService _preferences;
  final _auth = LocalAuthentication();

  Future<bool> isPinSet() async {
    final hash = await _preferences.getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _preferences.setPinHash(hash);
    await _preferences.setPinEnabled(true);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _preferences.getPinHash();
    if (storedHash == null) {
      return false;
    }
    return storedHash == _hashPin(pin);
  }

  Future<bool> authenticateWithBiometrics() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    if (!canCheck || !isSupported) {
      return false;
    }
    return _auth.authenticate(
      localizedReason: 'Authenticate to unlock WekaCert',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
