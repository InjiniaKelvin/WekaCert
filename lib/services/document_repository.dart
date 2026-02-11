import '../models/backup_record.dart';
import '../models/document.dart';
import '../models/document_version.dart';
import '../models/document_with_versions.dart';
import 'database_service.dart';

class DocumentRepository {
  DocumentRepository(this._database);

  final DatabaseService _database;

  Future<void> addDocument(Document document, DocumentVersion version) async {
    await _database.insertDocument(document);
    await _database.insertDocumentVersion(version);
  }

  Future<void> addVersion(DocumentVersion version) async {
    await _database.insertDocumentVersion(version);
  }

  Future<void> updateDocument(Document document) async {
    await _database.updateDocument(document);
  }

  Future<void> deleteDocument(String documentId) async {
    await _database.deleteDocument(documentId);
  }

  Future<List<DocumentWithVersions>> fetchDocuments() async {
    return _database.fetchDocumentsWithVersions();
  }

  Future<DocumentWithVersions?> fetchDocument(String documentId) async {
    return _database.fetchDocumentWithVersions(documentId);
  }

  Future<void> upsertBackupRecord(BackupRecord record) async {
    await _database.upsertBackupRecord(record);
  }

  Future<List<BackupRecord>> fetchBackupRecords() async {
    return _database.fetchBackupRecords();
  }
}
