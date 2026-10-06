import 'package:flutter_test/flutter_test.dart';

import 'package:weka_cert/models/document_version.dart';
import 'package:weka_cert/services/backup_conflict_resolver.dart';

void main() {
  test('prefers the newest version by updatedAt', () {
    final resolver = BackupConflictResolver();
    final local = DocumentVersion(
      id: 'local',
      documentId: 'doc-1',
      filePath: '/tmp/local',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 8, 10, 10),
    );
    final remote = DocumentVersion(
      id: 'remote',
      documentId: 'doc-1',
      filePath: '/tmp/remote',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 8, 10, 9),
    );

    final chosen = resolver.resolve(local: local, remote: remote);

    expect(chosen.id, 'local');
  });

  test('prefers remote when it is newer', () {
    final resolver = BackupConflictResolver();
    final local = DocumentVersion(
      id: 'local',
      documentId: 'doc-1',
      filePath: '/tmp/local',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 8, 10, 9),
    );
    final remote = DocumentVersion(
      id: 'remote',
      documentId: 'doc-1',
      filePath: '/tmp/remote',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 8, 10, 10),
    );

    final chosen = resolver.resolve(local: local, remote: remote);

    expect(chosen.id, 'remote');
  });
}
