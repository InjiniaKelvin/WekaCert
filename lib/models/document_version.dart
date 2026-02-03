class DocumentVersion {
  DocumentVersion({
    required this.id,
    required this.documentId,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String documentId;
  final DateTime createdAt;
  final String? note;
}
