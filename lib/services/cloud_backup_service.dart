import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import '../models/backup_record.dart';
import '../models/document_version.dart';

class CloudBackupService {
  CloudBackupService({required String encryptionKey})
      : _key = Key(_deriveKey(encryptionKey));

  final Key _key;

  Future<BackupRecord> encryptAndStore({
    required DocumentVersion version,
    required File file,
  }) async {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key));
    final bytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final payload = jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
    });
    // TODO: upload payload to cloud provider.
    final cloudPath = 'cloud://${version.documentId}/${version.id}.enc';
    return BackupRecord(
      id: '${version.documentId}-${version.id}',
      documentId: version.documentId,
      versionId: version.id,
      cloudPath: cloudPath,
      updatedAt: DateTime.now(),
    );
  }

  Future<File> decryptFromPayload({
    required String payload,
    required String targetPath,
  }) async {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final iv = IV.fromBase64(map['iv'] as String);
    final data = map['data'] as String;
    final encrypter = Encrypter(AES(_key));
    final decrypted = encrypter.decryptBytes(Encrypted.fromBase64(data), iv: iv);
    final file = File(targetPath);
    await file.writeAsBytes(decrypted, flush: true);
    return file;
  }

  static List<int> _deriveKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

}
