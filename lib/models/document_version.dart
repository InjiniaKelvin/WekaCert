class DocumentVersion {
  DocumentVersion({
    required this.id,
    required this.documentId,
    required this.filePath,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String documentId;
  final String filePath;
  final DateTime createdAt;
  final String? note;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  static DocumentVersion fromMap(Map<String, Object?> map) {
    return DocumentVersion(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      filePath: map['filePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
    );
  }
}
