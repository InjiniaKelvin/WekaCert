import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/backup_record.dart';
import '../models/document_version.dart';
import 'api_service.dart';

/// Stores the already AES-GCM-encrypted local artifact for backup.
class CloudBackupService {
  CloudBackupService({required String encryptionKey, ApiService? api})
      : _api = api;

  final ApiService? _api;

  Future<BackupRecord> encryptAndStore({
    required DocumentVersion version,
    required File file,
  }) async {
    final backupPath = _api == null
        ? (await _createBackupFile(version)).path
        : await _api!.uploadBackup(
            version.documentId,
            version.id,
            await file.readAsBytes(),
          );
    if (_api == null) {
      await file.copy(backupPath);
    }
    return BackupRecord(
      id: '${version.documentId}-${version.id}',
      documentId: version.documentId,
      versionId: version.id,
      cloudPath: backupPath,
      updatedAt: DateTime.now(),
    );
  }

  Future<File> restoreFromBackup({
    required String payloadPath,
    required String targetPath,
    required String documentId,
    required String versionId,
  }) async {
    final bytes = _api == null
        ? await File(payloadPath).readAsBytes()
        : await _api!.downloadBackup(documentId, versionId, payloadPath);
    final file = File(targetPath);
    await file.writeAsBytes(bytes, flush: true);
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

}
