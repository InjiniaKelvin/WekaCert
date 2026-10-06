import '../models/document_version.dart';

class BackupConflictResolver {
  DocumentVersion resolve({
    required DocumentVersion local,
    required DocumentVersion remote,
  }) {
    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }
}
