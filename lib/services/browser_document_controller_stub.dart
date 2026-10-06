import 'dart:typed_data';

import '../models/backup_record.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_version.dart';
import '../models/document_with_versions.dart';
import 'api_service.dart';
import 'content_encryption_service.dart';
import 'local_document_service.dart';
import 'preferences_service.dart';

class BrowserDocumentController implements LocalDocumentService {
  BrowserDocumentController({
    required PreferencesService preferences,
    required ContentEncryptionService encryption,
    ApiService? api,
  });

  @override
  Future<List<DocumentWithVersions>> fetchDocuments() async => [];

  @override
  Future<DocumentWithVersions?> fetchDocument(String documentId) async => null;

  @override
  Future<void> addDocument({
    required String name,
    required DocumentCategory category,
    required bool isExpirable,
    DateTime? expiryDate,
    Uint8List? fileBytes,
    String? filePath,
    required String fileName,
    String? note,
  }) async {
    throw UnsupportedError('BrowserDocumentController is only available on web');
  }

  @override
  Future<void> addVersion({
    required Document document,
    Uint8List? fileBytes,
    String? filePath,
    required String fileName,
    String? note,
  }) async {
    throw UnsupportedError('BrowserDocumentController is only available on web');
  }

  @override
  Future<void> updateDocument(Document document) async {
    throw UnsupportedError('BrowserDocumentController is only available on web');
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    throw UnsupportedError('BrowserDocumentController is only available on web');
  }

  @override
  Future<void> openFile(String filePath) async {}

  @override
  Future<List<BackupRecord>> fetchBackupRecords() async => [];

  @override
  Future<BackupRecord?> backupVersion(DocumentVersion version) async => null;

  @override
  Future<bool> restoreLatestBackup(Document document) async => false;

  @override
  Future<bool> restoreBackupRecord(
    BackupRecord record,
    Document document,
  ) async => false;
}
