import 'dart:async';

import 'package:uuid/uuid.dart';

import 'dart:io';

import '../models/backup_record.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_filter.dart';
import '../models/document_version.dart';
import '../models/document_with_versions.dart';
import '../utils/date_utils.dart';
import 'cloud_backup_service.dart';
import 'document_repository.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

class DocumentController {
  DocumentController({
    required DocumentRepository repository,
    required NotificationService notifications,
    required PreferencesService preferences,
    CloudBackupService? backup,
  })  : _repository = repository,
        _notifications = notifications,
        _preferences = preferences,
        _backup = backup;

  final DocumentRepository _repository;
  final NotificationService _notifications;
  final PreferencesService _preferences;
  final CloudBackupService? _backup;
  final _uuid = const Uuid();

  final _documents = StreamController<List<DocumentWithVersions>>.broadcast();

  Stream<List<DocumentWithVersions>> get documentsStream => _documents.stream;

  Future<void> loadDocuments() async {
    final docs = await _repository.fetchDocuments();
    _documents.add(docs);
  }

  Future<void> addDocument({
    required String name,
    required DocumentCategory category,
    required bool isExpirable,
    DateTime? expiryDate,
    required String filePath,
    String? note,
  }) async {
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
      filePath: filePath,
      createdAt: now,
      note: note,
    );
    await _repository.addDocument(document, version);
    await _scheduleReminder(document);
    await loadDocuments();
  }

  Future<void> addVersion({
    required Document document,
    required String filePath,
    String? note,
  }) async {
    final version = DocumentVersion(
      id: _uuid.v4(),
      documentId: document.id,
      filePath: filePath,
      createdAt: DateTime.now(),
      note: note,
    );
    await _repository.addVersion(version);
    await loadDocuments();
  }

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

  Future<List<BackupRecord>> fetchBackupRecords() async {
    return _repository.fetchBackupRecords();
  }

  Future<void> updateDocument(Document document) async {
    await _repository.updateDocument(document);
    await _scheduleReminder(document);
    await loadDocuments();
  }

  Future<void> deleteDocument(String documentId) async {
    await _repository.deleteDocument(documentId);
    await _notifications.cancelReminder(documentId);
    await loadDocuments();
  }

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
