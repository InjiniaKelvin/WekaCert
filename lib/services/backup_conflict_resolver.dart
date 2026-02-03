import '../models/document_version.dart';

class BackupConflictResolver {
  DocumentVersion resolve({
    required DocumentVersion local,
    required DocumentVersion remote,
  }) {
    if (local.createdAt.isAfter(remote.createdAt)) {
      return local;
    }
    return remote;
  }
}
