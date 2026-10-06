import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_version.dart';
import 'preferences_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    required this.baseUrl,
    required this.prefs,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final PreferencesService prefs;
  final http.Client _client;

  // ── Auth helpers ──────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await prefs.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await prefs.clearToken();
      throw ApiException('Session expired. Please log in again.',
          statusCode: 401);
    }
    if (response.statusCode >= 400) {
      String msg = 'Request failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['message'] is String) {
          msg = body['message'] as String;
        } else if (body['message'] is List) {
          msg = (body['message'] as List).join(', ');
        }
      } catch (_) {}
      throw ApiException(msg, statusCode: response.statusCode);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  // ── Authentication ────────────────────────────────────────────────────────

  Future<String> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    await prefs.setToken(token);
    await prefs.setUserEmail(email);
    return token;
  }

  Future<String> register(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    await prefs.setToken(token);
    await prefs.setUserEmail(email);
    return token;
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  Future<List<Document>> listDocuments() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/documents'),
        headers: await _authHeaders(),
      );
      final data = await _handleResponse(response) as List<dynamic>;
      final documents = data
          .cast<Map<String, dynamic>>()
          .map(_documentFromJson)
          .toList();
      await _cacheDocuments(documents);
      return documents;
    } on ApiException catch (e) {
      if (e.statusCode == 401) rethrow;
      final cached = await _readCachedDocuments();
      if (cached != null) return cached;
      rethrow;
    } catch (_) {
      final cached = await _readCachedDocuments();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Document> createDocument({
    required String name,
    required String category,
    required bool isExpirable,
    DateTime? expiryDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/documents'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        'category': category,
        'isExpirable': isExpirable,
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
      }),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final document = _documentFromJson(data);
    final documents = await _readCachedDocuments() ?? <Document>[];
    final updatedDocuments = [
      document,
      ...documents.where((item) => item.id != document.id),
    ];
    await _cacheDocuments(updatedDocuments);
    await _cacheDocumentBundle(document, const []);
    return document;
  }

  Future<Map<String, dynamic>> getDocument(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/documents/$id'),
        headers: await _authHeaders(),
      );
      final data = await _handleResponse(response) as Map<String, dynamic>;
      final document = _documentFromJson(data['document'] as Map<String, dynamic>);
      final versions = (data['versions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_versionFromJson)
          .toList();
      await _cacheDocumentBundle(document, versions);
      return {'document': document, 'versions': versions};
    } on ApiException catch (e) {
      if (e.statusCode == 401) rethrow;
      final cached = await _readCachedDocumentBundle(id);
      if (cached != null) return cached;
      rethrow;
    } catch (_) {
      final cached = await _readCachedDocumentBundle(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Document> updateDocument(
    String id, {
    String? name,
    String? category,
    bool? isExpirable,
    DateTime? expiryDate,
    bool clearExpiry = false,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/documents/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (isExpirable != null) 'isExpirable': isExpirable,
        if (clearExpiry) 'expiryDate': null,
        if (!clearExpiry && expiryDate != null)
          'expiryDate': expiryDate.toIso8601String(),
      }),
    );
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final document = _documentFromJson(data);
    final documents = await _readCachedDocuments();
    if (documents != null) {
      final updatedDocuments = documents
          .map((item) => item.id == document.id ? document : item)
          .toList();
      await _cacheDocuments(updatedDocuments);
    }
    await _cacheDocumentBundle(document, const []);
    return document;
  }

  Future<void> deleteDocument(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/documents/$id'),
      headers: await _authHeaders(),
    );
    await _handleResponse(response);
    final documents = await _readCachedDocuments();
    if (documents != null) {
      await _cacheDocuments(
        documents.where((document) => document.id != id).toList(),
      );
    }
    await prefs.clearCachedDocumentJson(id);
  }

  // ── File upload ───────────────────────────────────────────────────────────

  Future<DocumentVersion> uploadFile(
    String documentId,
    Uint8List bytes,
    String filename, {
    String? note,
  }) async {
    final token = await prefs.getToken();
    final uri = Uri.parse('$baseUrl/documents/$documentId/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename));
    if (note != null && note.isNotEmpty) {
      request.fields['note'] = note;
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = await _handleResponse(response) as Map<String, dynamic>;
    final version = _versionFromJson(data);
    final cached = await _readCachedDocumentBundle(documentId);
    if (cached != null) {
      final document = cached['document'] as Document;
      final versions = <DocumentVersion>[
        version,
        ...(cached['versions'] as List<DocumentVersion>)
            .where((item) => item.id != version.id),
      ];
      await _cacheDocumentBundle(document, versions);
    }
    return version;
  }

  Future<String> uploadBackup(
    String documentId,
    String versionId,
    Uint8List bytes,
  ) async {
    final token = await prefs.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/$documentId/versions/$versionId/backup'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'backup.enc'));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = await _handleResponse(response) as Map<String, dynamic>;
    return data['objectKey'] as String;
  }

  Future<Uint8List> downloadBackup(
    String documentId,
    String versionId,
    String objectKey,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/documents/$documentId/versions/$versionId/backup'
        '?objectKey=${Uri.encodeQueryComponent(objectKey)}',
      ),
      headers: await _authHeaders(),
    );
    if (response.statusCode >= 400) {
      await _handleResponse(response);
    }
    return response.bodyBytes;
  }

  // ── Versions ──────────────────────────────────────────────────────────────

  Future<List<DocumentVersion>> listVersions(String documentId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/documents/$documentId/versions'),
      headers: await _authHeaders(),
    );
    final data = await _handleResponse(response) as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(_versionFromJson)
        .toList();
  }

  String fileUrl(String documentId, String versionId) =>
      '$baseUrl/documents/$documentId/versions/$versionId/file';

  // ── JSON helpers ──────────────────────────────────────────────────────────

  Document _documentFromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      name: json['name'] as String,
      category: DocumentCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String),
        orElse: () => DocumentCategory.other,
      ),
      isExpirable: json['isExpirable'] as bool,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  DocumentVersion _versionFromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String;
    return DocumentVersion(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      filePath: json['objectKey'] as String,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(createdAt),
      note: json['note'] as String?,
    );
  }

  Future<void> _cacheDocuments(List<Document> documents) async {
    final payload = jsonEncode(
      documents.map((document) => document.toMap()).toList(),
    );
    await prefs.setCachedDocumentsJson(payload);
  }

  Future<List<Document>?> _readCachedDocuments() async {
    final raw = await prefs.getCachedDocumentsJson();
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Document.fromMap)
        .toList();
  }

  Future<void> _cacheDocumentBundle(
    Document document,
    List<DocumentVersion> versions,
  ) async {
    final payload = jsonEncode({
      'document': document.toMap(),
      'versions': versions.map((version) => version.toMap()).toList(),
    });
    await prefs.setCachedDocumentJson(document.id, payload);
  }

  Future<Map<String, dynamic>?> _readCachedDocumentBundle(String id) async {
    final raw = await prefs.getCachedDocumentJson(id);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final document = Document.fromMap(decoded['document'] as Map<String, dynamic>);
    final versions = (decoded['versions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_versionFromJson)
        .toList();
    return {'document': document, 'versions': versions};
  }
}
