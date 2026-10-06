import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';

/// Provides authenticated AES-256-GCM encryption for document content.
class ContentEncryptionService {
  ContentEncryptionService({required String keyMaterial})
      : _secretKey = SecretKey(_deriveKey(keyMaterial));

  static final _algorithm = AesGcm.with256bits();
  final SecretKey _secretKey;

  Future<Uint8List> encrypt(Uint8List bytes) async {
    final secretBox = await _algorithm.encrypt(bytes, secretKey: _secretKey);
    return Uint8List.fromList(secretBox.concatenation());
  }

  Future<Uint8List> decrypt(Uint8List bytes) async {
    final secretBox = SecretBox.fromConcatenation(
      bytes,
      nonceLength: 12,
      macLength: 16,
    );
    final decrypted = await _algorithm.decrypt(secretBox, secretKey: _secretKey);
    return Uint8List.fromList(decrypted);
  }

  static Uint8List _deriveKey(String keyMaterial) {
    return Uint8List.fromList(sha256.convert(keyMaterial.codeUnits).bytes);
  }
}
