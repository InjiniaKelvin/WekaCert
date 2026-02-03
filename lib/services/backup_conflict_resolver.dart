import '../models/document_version.dart';

class BackupConflictResolver {
  DocumentVersion resolve({
    required DocumentVersion local,
    required DocumentVersion remote,
  }) {
    if (remote.createdAt.isAfter(local.createdAt)) {
      return remote;
    }
    return local;
  }
}
