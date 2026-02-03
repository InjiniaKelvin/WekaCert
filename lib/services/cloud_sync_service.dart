import 'dart:io';

import '../models/document_version.dart';
import 'backup_conflict_resolver.dart';
import 'cloud_backup_service.dart';

class CloudSyncService {
  CloudSyncService({
    required CloudBackupService backup,
    BackupConflictResolver? resolver,
  })  : _backup = backup,
        _resolver = resolver ?? BackupConflictResolver();

  final CloudBackupService _backup;
  final BackupConflictResolver _resolver;

  Future<DocumentVersion> resolveConflict({
    required DocumentVersion local,
    required DocumentVersion remote,
  }) async {
    return _resolver.resolve(local: local, remote: remote);
  }

  Future<void> backupFile(DocumentVersion version, File file) async {
    await _backup.encryptAndStore(version: version, file: file);
  }
}
