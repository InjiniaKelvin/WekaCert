class DocumentVersion {
  DocumentVersion({
    required this.id,
    required this.documentId,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final String documentId;
  final String filePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'note': note,
    };
  }

  static DocumentVersion fromMap(Map<String, Object?> map) {
    return DocumentVersion(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      filePath: map['filePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(_normalizeTimestamp(map['updatedAt'] as String)),
      note: map['note'] as String?,
    );
  }

  static String _normalizeTimestamp(String raw) {
    var normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    if (DateTime.tryParse(normalized) != null) {
      return normalized;
    }
    if (normalized.contains('.')) {
      final trimmed = normalized.split('.').first;
      return trimmed;
    }
    return normalized;
  }
}
