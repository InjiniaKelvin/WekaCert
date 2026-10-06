import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/backup_record.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_filter.dart';
import '../models/document_version.dart';
import '../models/document_with_versions.dart';
import '../utils/date_utils.dart';
import 'cloud_backup_service.dart';
import 'local_document_service.dart';
import 'document_repository.dart';
import 'file_encryption_service.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

class DocumentController implements LocalDocumentService {
  DocumentController({
    required DocumentRepository repository,
    required NotificationService notifications,
    required PreferencesService preferences,
    required FileEncryptionService fileEncryption,
    CloudBackupService? backup,
  })  : _repository = repository,
        _notifications = notifications,
        _preferences = preferences,
        _fileEncryption = fileEncryption,
        _backup = backup;

  final DocumentRepository _repository;
  final NotificationService _notifications;
  final PreferencesService _preferences;
  final FileEncryptionService _fileEncryption;
  final CloudBackupService? _backup;
  final _uuid = const Uuid();

  final _documents = StreamController<List<DocumentWithVersions>>.broadcast();

  Stream<List<DocumentWithVersions>> get documentsStream => _documents.stream;

  @override
  Future<List<DocumentWithVersions>> fetchDocuments() async {
    return _repository.fetchDocuments();
  }

  Future<void> loadDocuments() async {
    final docs = await _repository.fetchDocuments();
    _documents.add(docs);
  }

  /// Encrypt [sourcePath] into the app's private documents directory.
  Future<String> _copyToSecureStorage(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final secureDir = Directory(p.join(directory.path, 'secure_docs'));
    if (!secureDir.existsSync()) {
      await secureDir.create(recursive: true);
    }
    final destPath = p.join(secureDir.path, '${_uuid.v4()}.enc');
    await _fileEncryption.encryptFile(
      sourcePath: sourcePath,
      destinationPath: destPath,
    );
    return destPath;
  }

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
    if (filePath == null) {
      throw ArgumentError('filePath is required for mobile local storage');
    }
    final securePath = await _copyToSecureStorage(filePath);
    final now = DateTime.now();
    final document = Document(
      id: _uuid.v4(),
      name: name,
      category: category,
      isExpirable: isExpirable,
      expiryDate: expiryDate,
      createdAt: now,
    );
    final version = DocumentVersion(
      id: _uuid.v4(),
      documentId: document.id,
      filePath: securePath,
      createdAt: now,
      updatedAt: now,
      note: note,
    );
    await _repository.addDocument(document, version);
    await _scheduleReminder(document);
    await loadDocuments();
  }

  @override
  Future<void> addVersion({
    required Document document,
    Uint8List? fileBytes,
    String? filePath,
    required String fileName,
    String? note,
    bool skipCopy = false,
  }) async {
    if (filePath == null) {
      throw ArgumentError('filePath is required for mobile local storage');
    }
    final securePath =
        skipCopy ? filePath : await _copyToSecureStorage(filePath);
    final now = DateTime.now();
    final version = DocumentVersion(
      id: _uuid.v4(),
      documentId: document.id,
      filePath: securePath,
      createdAt: now,
      updatedAt: now,
      note: note,
    );
    await _repository.addVersion(version);
    await loadDocuments();
  }

  /// Open a document file using the device's default viewer.
  @override
  Future<void> openFile(String filePath) async {
    final decryptedFile = await _fileEncryption.decryptForViewing(filePath);
    await OpenFilex.open(decryptedFile.path);
  }

  @override
  Future<void> updateDocument(Document document) async {
    await _repository.updateDocument(document);
    await _scheduleReminder(document);
    await loadDocuments();
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _repository.deleteDocument(documentId);
    await _notifications.cancelReminder(documentId);
    await loadDocuments();
  }

  @override
  Future<DocumentWithVersions?> fetchDocument(String documentId) async {
    return _repository.fetchDocument(documentId);
  }

  Future<List<DocumentWithVersions>> filterDocuments(
    List<DocumentWithVersions> docs,
    DocumentFilter filter,
    int reminderDays,
  ) async {
    return docs.where((item) {
      final matchesSearch = filter.searchQuery.isEmpty ||
          item.document.name
              .toLowerCase()
              .contains(filter.searchQuery.toLowerCase());
      final matchesCategory =
          filter.category == null || item.document.category == filter.category;
      final matchesExpirable = filter.isExpirable == null ||
          item.document.isExpirable == filter.isExpirable;
      final expiryStatus = statusForExpiry(
        isExpirable: item.document.isExpirable,
        expiryDate: item.document.expiryDate,
        reminderDays: reminderDays,
      );
      final matchesStatus = filter.expiryStatus == null ||
          toFilterStatus(expiryStatus) == filter.expiryStatus;
      return matchesSearch &&
          matchesCategory &&
          matchesExpirable &&
          matchesStatus;
    }).toList();
  }

  @override
  Future<BackupRecord?> backupVersion(DocumentVersion version) async {
    if (_backup == null) {
      return null;
    }
    final file = File(version.filePath);
    if (!file.existsSync()) {
      return null;
    }
    final record = await _backup!.encryptAndStore(version: version, file: file);
    await _repository.upsertBackupRecord(record);
    return record;
  }

  @override
  Future<bool> restoreLatestBackup(Document document) async {
    if (_backup == null) {
      return false;
    }
    final records = await _repository.fetchBackupRecords();
    final candidates = records
        .where((record) => record.documentId == document.id)
        .toList();
    if (candidates.isEmpty) {
      return false;
    }
    candidates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final record = candidates.first;
    return restoreBackupRecord(record, document);
  }

  @override
  Future<bool> restoreBackupRecord(
    BackupRecord record,
    Document document,
  ) async {
    if (_backup == null) {
      return false;
    }
    final directory = await getApplicationDocumentsDirectory();
    final filename = 'restored_${record.versionId}.bin';
    final targetPath = p.join(directory.path, filename);
    final restored = await _backup!.restoreFromBackup(
      payloadPath: record.cloudPath,
      targetPath: targetPath,
      documentId: document.id,
      versionId: record.versionId,
    );
    await addVersion(
      document: document,
      filePath: restored.path,
      fileName: filename,
      note: 'Restored from backup',
    );
    await restored.delete();
    return true;
  }

  @override
  Future<List<BackupRecord>> fetchBackupRecords() async {
    return _repository.fetchBackupRecords();
  }

  Future<void> _scheduleReminder(Document document) async {
    final reminderDays = await _preferences.getReminderDays();
    await _notifications.scheduleExpiryReminder(
      document: document,
      reminderDays: reminderDays,
    );
  }

  void dispose() {
    _documents.close();
  }
}
