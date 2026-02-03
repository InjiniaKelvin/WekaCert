import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/backup_record.dart';
import '../models/document.dart';
import '../models/document_version.dart';
import '../models/document_with_versions.dart';

class DatabaseService {
  DatabaseService({required this.encryptionKey});

  final String encryptionKey;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, 'weka_cert.db');
    return openDatabase(
      dbPath,
      version: 1,
      password: encryptionKey,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            isExpirable INTEGER NOT NULL,
            expiryDate TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE document_versions (
            id TEXT PRIMARY KEY,
            documentId TEXT NOT NULL,
            filePath TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY(documentId) REFERENCES documents(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE backup_records (
            id TEXT PRIMARY KEY,
            documentId TEXT NOT NULL,
            versionId TEXT NOT NULL,
            cloudPath TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY(documentId) REFERENCES documents(id),
            FOREIGN KEY(versionId) REFERENCES document_versions(id)
          )
        ''');
      },
    );
  }

  Future<void> insertDocument(Document document) async {
    final db = await database;
    await db.insert('documents', document.toMap());
  }

  Future<void> insertDocumentVersion(DocumentVersion version) async {
    final db = await database;
    await db.insert('document_versions', version.toMap());
  }

  Future<void> updateDocument(Document document) async {
    final db = await database;
    await db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> deleteDocument(String documentId) async {
    final db = await database;
    await db.delete('backup_records',
        where: 'documentId = ?', whereArgs: [documentId]);
    await db.delete('document_versions',
        where: 'documentId = ?', whereArgs: [documentId]);
    await db.delete('documents', where: 'id = ?', whereArgs: [documentId]);
  }

  Future<List<Document>> fetchDocuments() async {
    final db = await database;
    final rows = await db.query('documents', orderBy: 'createdAt DESC');
    return rows.map(Document.fromMap).toList();
  }

  Future<List<DocumentVersion>> fetchVersions(String documentId) async {
    final db = await database;
    final rows = await db.query(
      'document_versions',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(DocumentVersion.fromMap).toList();
  }

  Future<DocumentWithVersions?> fetchDocumentWithVersions(String documentId) async {
    final db = await database;
    final docs = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [documentId],
    );
    if (docs.isEmpty) {
      return null;
    }
    final versions = await fetchVersions(documentId);
    return DocumentWithVersions(
      document: Document.fromMap(docs.first),
      versions: versions,
    );
  }

  Future<List<DocumentWithVersions>> fetchDocumentsWithVersions() async {
    final docs = await fetchDocuments();
    final result = <DocumentWithVersions>[];
    for (final doc in docs) {
      result.add(DocumentWithVersions(
        document: doc,
        versions: await fetchVersions(doc.id),
      ));
    }
    return result;
  }

  Future<void> upsertBackupRecord(BackupRecord record) async {
    final db = await database;
    await db.insert(
      'backup_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BackupRecord>> fetchBackupRecords() async {
    final db = await database;
    final rows = await db.query('backup_records', orderBy: 'updatedAt DESC');
    return rows.map(BackupRecord.fromMap).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
    _database = null;
  }
}
