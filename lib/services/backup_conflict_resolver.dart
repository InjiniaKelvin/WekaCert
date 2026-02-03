import '../models/document_version.dart';

class BackupConflictResolver {
  DocumentVersion resolve({
    required DocumentVersion local,
    required DocumentVersion remote,
  }) {
    final localTime = local.updatedAt ?? local.createdAt;
    final remoteTime = remote.updatedAt ?? remote.createdAt;
    return localTime.isAfter(remoteTime) ? local : remote;
  }
}
