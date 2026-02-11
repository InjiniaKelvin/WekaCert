import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class KeyManagementService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'weka_cert_db_key';

  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newKey = const Uuid().v4();
    await _storage.write(key: _keyName, value: newKey);
    return newKey;
  }
}
