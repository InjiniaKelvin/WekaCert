import 'dart:typed_data';

import '../models/backup_record.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_version.dart';
import '../models/document_with_versions.dart';

abstract class LocalDocumentService {
  Future<List<DocumentWithVersions>> fetchDocuments();

  Future<DocumentWithVersions?> fetchDocument(String documentId);

  Future<void> addDocument({
    required String name,
    required DocumentCategory category,
    required bool isExpirable,
    DateTime? expiryDate,
    Uint8List? fileBytes,
    String? filePath,
    required String fileName,
    String? note,
  });

  Future<void> addVersion({
    required Document document,
    Uint8List? fileBytes,
    String? filePath,
    required String fileName,
    String? note,
  });

  Future<void> updateDocument(Document document);

  Future<void> deleteDocument(String documentId);

  Future<void> openFile(String filePath);

  Future<List<BackupRecord>> fetchBackupRecords() async => [];

  Future<BackupRecord?> backupVersion(DocumentVersion version) async => null;

  Future<bool> restoreLatestBackup(Document document) async => false;

  Future<bool> restoreBackupRecord(
    BackupRecord record,
    Document document,
  ) async => false;
}