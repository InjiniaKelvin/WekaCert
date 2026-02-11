import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/backup_record.dart';
import '../models/document_version.dart';

/// Encrypts document bytes for cloud backup using AES with a random IV.
/// Produces a base64 payload ready for upload to providers like Google Drive.
/// Replace the placeholder cloud path with real remote storage identifiers.
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
    final backupFile = await _createBackupFile(version);
    await backupFile.writeAsString(payload, flush: true);
    return BackupRecord(
      id: '${version.documentId}-${version.id}',
      documentId: version.documentId,
      versionId: version.id,
      cloudPath: backupFile.path,
      updatedAt: DateTime.now(),
    );
  }

  Future<File> restoreFromBackup({
    required String payloadPath,
    required String targetPath,
  }) async {
    final payload = await File(payloadPath).readAsString();
    return decryptFromPayload(payload: payload, targetPath: targetPath);
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

  Future<File> _createBackupFile(DocumentVersion version) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));
    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
    }
    final filename = '${version.documentId}-${version.id}.enc';
    return File(path.join(backupDir.path, filename));
  }

  static List<int> _deriveKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }
}
