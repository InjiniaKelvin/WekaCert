import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart' as idb;
import 'package:uuid/uuid.dart';

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
  })
      : _encryption = encryption,
        _api = api;

  final ContentEncryptionService _encryption;
  final ApiService? _api;
  final _uuid = const Uuid();

  static const _dbName = 'weka_cert_browser_vault';
  static const _dbVersion = 1;
  static const _documentsStore = 'documents';
  static const _versionsStore = 'versions';
  static const _operationsStore = 'operations';

  Future<idb.Database>? _databaseFuture;

  Future<idb.Database> get _database async {
    _databaseFuture ??= _openDatabase();
    return _databaseFuture!;
  }

  Future<idb.Database> _openDatabase() async {
    if (!idb.idbFactoryWebSupported) {
      throw StateError('IndexedDB is not supported in this browser.');
    }
    return idb.idbFactoryWeb.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (event) {
        final db = event.database;
        if (!db.objectStoreNames.contains(_documentsStore)) {
          db.createObjectStore(_documentsStore, keyPath: 'id');
        }
        if (!db.objectStoreNames.contains(_versionsStore)) {
          final store = db.createObjectStore(_versionsStore, keyPath: 'id');
          store.createIndex('documentId', 'documentId', unique: false);
        }
        if (!db.objectStoreNames.contains(_operationsStore)) {
          db.createObjectStore(_operationsStore, keyPath: 'id');
        }
      },
    );
  }

  Future<void> _put(String storeName, Map<String, Object?> value) async {
    final db = await _database;
    final txn = db.transaction(storeName, 'readwrite');
    await txn.objectStore(storeName).put(value);
    await txn.completed;
  }

  Future<void> _delete(String storeName, String key) async {
    final db = await _database;
    final txn = db.transaction(storeName, 'readwrite');
    await txn.objectStore(storeName).delete(key);
    await txn.completed;
  }

  Future<List<Map<String, Object?>>> _getAll(String storeName) async {
    final db = await _database;
    final txn = db.transaction(storeName, 'readonly');
    final raw = await txn.objectStore(storeName).getAll();
    await txn.completed;
    return raw.map((item) => Map<String, Object?>.from(item as Map)).toList();
  }

  Future<Map<String, Object?>?> _getById(String storeName, String id) async {
    final db = await _database;
    final txn = db.transaction(storeName, 'readonly');
    final raw = await txn.objectStore(storeName).getObject(id);
    await txn.completed;
    if (raw == null) return null;
    return Map<String, Object?>.from(raw as Map);
  }

  Map<String, Object?> _documentToMap(Document document, {String? remoteId}) {
    return {
      'id': document.id,
      'remoteId': remoteId,
      'name': document.name,
      'category': document.category.name,
      'isExpirable': document.isExpirable ? 1 : 0,
      'expiryDate': document.expiryDate?.toIso8601String(),
      'createdAt': document.createdAt.toIso8601String(),
    };
  }

  Document _documentFromMap(Map<String, Object?> map) {
    return Document(
      id: map['id'] as String,
      name: map['name'] as String,
      category: DocumentCategory.values.firstWhere(
        (category) => category.name == map['category'],
        orElse: () => DocumentCategory.other,
      ),
      isExpirable: (map['isExpirable'] as int) == 1,
      expiryDate: map['expiryDate'] == null
          ? null
          : DateTime.parse(map['expiryDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, Object?> _versionToMap(
    DocumentVersion version, {
    String? remoteId,
    String? fileName,
    Uint8List? fileBytes,
  }) {
    return {
      'id': version.id,
      'remoteId': remoteId,
      'documentId': version.documentId,
      'filePath': version.id,
      'fileName': fileName,
      'fileBytesBase64': fileBytes == null ? null : base64Encode(fileBytes),
      'createdAt': version.createdAt.toIso8601String(),
      'updatedAt': version.updatedAt.toIso8601String(),
      'note': version.note,
    };
  }

  DocumentVersion _versionFromMap(Map<String, Object?> map) {
    return DocumentVersion(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      filePath: map['filePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      note: map['note'] as String?,
    );
  }

  Future<void> _enqueueOperation(Map<String, Object?> operation) async {
    await _put(_operationsStore, operation);
  }

  Future<List<Map<String, Object?>>> _loadOperations() async {
    final operations = await _getAll(_operationsStore);
    operations.sort((a, b) =>
        (a['createdAt'] as String).compareTo(b['createdAt'] as String));
    return operations;
  }

  Future<void> _removeOperation(String id) async {
    await _delete(_operationsStore, id);
  }

  Future<void> syncPendingOperations() async {
    final api = _api;
    if (api == null) return;
    final operations = await _loadOperations();
    for (final operation in operations) {
      try {
        final type = operation['type'] as String;
        switch (type) {
          case 'createDocument':
            await _syncCreate(operation, api);
            break;
          case 'addVersion':
            await _syncAddVersion(operation, api);
            break;
          case 'updateDocument':
            await _syncUpdate(operation, api);
            break;
          case 'deleteDocument':
            await _syncDelete(operation, api);
            break;
          default:
            break;
        }
        await _removeOperation(operation['id'] as String);
      } catch (_) {
        break;
      }
    }
  }

  Future<void> _syncCreate(Map<String, Object?> operation, ApiService api) async {
    final documentId = operation['documentId'] as String;
    final docMap = Map<String, Object?>.from(
      jsonDecode(operation['document'] as String) as Map,
    );
    final versionMap = Map<String, Object?>.from(
      jsonDecode(operation['version'] as String) as Map,
    );
    final document = _documentFromMap(docMap);
    final created = await api.createDocument(
      name: document.name,
      category: document.category.name,
      isExpirable: document.isExpirable,
      expiryDate: document.expiryDate,
    );
    final versionBytes = base64Decode(versionMap['fileBytesBase64'] as String);
    final version = await api.uploadFile(
      created.id,
      versionBytes,
      versionMap['fileName'] as String,
      note: versionMap['note'] as String?,
    );
    final storedDocument = await _getById(_documentsStore, documentId);
    if (storedDocument != null) {
      storedDocument['remoteId'] = created.id;
      await _put(_documentsStore, storedDocument);
    }
    final storedVersion = await _getById(_versionsStore, versionMap['id'] as String);
    if (storedVersion != null) {
      storedVersion['remoteId'] = version.id;
      await _put(_versionsStore, storedVersion);
    }
  }

  Future<void> _syncAddVersion(Map<String, Object?> operation, ApiService api) async {
    final localDocumentId = operation['documentId'] as String;
    final doc = await _getById(_documentsStore, localDocumentId);
    if (doc == null || doc['remoteId'] == null) return;
    final versionId = operation['versionId'] as String;
    final version = await _getById(_versionsStore, versionId);
    if (version == null) return;
    final uploaded = await api.uploadFile(
      doc['remoteId'] as String,
      base64Decode(version['fileBytesBase64'] as String),
      version['fileName'] as String,
      note: version['note'] as String?,
    );
    version['remoteId'] = uploaded.id;
    await _put(_versionsStore, version);
  }

  Future<void> _syncUpdate(Map<String, Object?> operation, ApiService api) async {
    final documentId = operation['documentId'] as String;
    final doc = await _getById(_documentsStore, documentId);
    if (doc == null || doc['remoteId'] == null) return;
    final document = _documentFromMap(doc);
    await api.updateDocument(
      doc['remoteId'] as String,
      name: document.name,
      category: document.category.name,
      isExpirable: document.isExpirable,
      expiryDate: document.expiryDate,
      clearExpiry: !document.isExpirable,
    );
  }

  Future<void> _syncDelete(Map<String, Object?> operation, ApiService api) async {
    final documentId = operation['documentId'] as String;
    final doc = await _getById(_documentsStore, documentId);
    if (doc == null || doc['remoteId'] == null) return;
    await api.deleteDocument(doc['remoteId'] as String);
  }

  @override
  Future<List<DocumentWithVersions>> fetchDocuments() async {
    await syncPendingOperations();
    final documents = await _getAll(_documentsStore);
    final versions = await _getAll(_versionsStore);
    return documents.map((docMap) {
      final document = _documentFromMap(docMap);
      final docVersions = versions
          .where((versionMap) => versionMap['documentId'] == document.id)
          .map(_versionFromMap)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return DocumentWithVersions(document: document, versions: docVersions);
    }).toList()
      ..sort((a, b) => b.document.createdAt.compareTo(a.document.createdAt));
  }

  @override
  Future<DocumentWithVersions?> fetchDocument(String documentId) async {
    await syncPendingOperations();
    final doc = await _getById(_documentsStore, documentId);
    if (doc == null) return null;
    final versions = await _getAll(_versionsStore);
    final documentVersions = versions
        .where((versionMap) => versionMap['documentId'] == documentId)
        .map(_versionFromMap)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return DocumentWithVersions(
      document: _documentFromMap(doc),
      versions: documentVersions,
    );
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
    if (fileBytes == null) {
      throw ArgumentError('fileBytes are required for browser local storage');
    }
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
      filePath: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      note: note,
    );
    await _put(_documentsStore, _documentToMap(document));
    final encryptedBytes = await _encryption.encrypt(fileBytes);
    await _put(
      _versionsStore,
      _versionToMap(
        version,
        fileName: fileName,
        fileBytes: encryptedBytes,
      ),
    );
    await _enqueueOperation({
      'id': _uuid.v4(),
      'type': 'createDocument',
      'documentId': document.id,
      'versionId': version.id,
      'document': jsonEncode(_documentToMap(document)),
      'version': jsonEncode({
        'id': version.id,
        'fileName': fileName,
        'fileBytesBase64': base64Encode(encryptedBytes),
        'note': note,
      }),
      'createdAt': now.toIso8601String(),
    });
    await syncPendingOperations();
  }

  @override
  Future<void> addVersion({
    required Document document,
    Uint8List? fileBytes,
    String? filePath,
    required String fileName,
    String? note,
  }) async {
    if (fileBytes == null) {
      throw ArgumentError('fileBytes are required for browser local storage');
    }
    final now = DateTime.now();
    final version = DocumentVersion(
      id: _uuid.v4(),
      documentId: document.id,
      filePath: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      note: note,
    );
    final encryptedBytes = await _encryption.encrypt(fileBytes);
    await _put(
      _versionsStore,
      _versionToMap(
        version,
        fileName: fileName,
        fileBytes: encryptedBytes,
      ),
    );
    await _enqueueOperation({
      'id': _uuid.v4(),
      'type': 'addVersion',
      'documentId': document.id,
      'versionId': version.id,
      'createdAt': now.toIso8601String(),
    });
    await syncPendingOperations();
  }

  @override
  Future<void> updateDocument(Document document) async {
    final existing = await _getById(_documentsStore, document.id);
    if (existing == null) return;
    existing.addAll(_documentToMap(document));
    await _put(_documentsStore, existing);
    await _enqueueOperation({
      'id': _uuid.v4(),
      'type': 'updateDocument',
      'documentId': document.id,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await syncPendingOperations();
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _delete(_documentsStore, documentId);
    final versions = await _getAll(_versionsStore);
    final related = versions.where((version) => version['documentId'] == documentId).toList();
    for (final version in related) {
      await _delete(_versionsStore, version['id'] as String);
    }
    await _enqueueOperation({
      'id': _uuid.v4(),
      'type': 'deleteDocument',
      'documentId': documentId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await syncPendingOperations();
  }

  @override
  Future<void> openFile(String filePath) async {
    final version = await _getById(_versionsStore, filePath);
    if (version == null) return;
    final bytes = await _encryption.decrypt(
      base64Decode(version['fileBytesBase64'] as String),
    );
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future<void>.delayed(const Duration(seconds: 15), () {
      html.Url.revokeObjectUrl(url);
    });
  }

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
