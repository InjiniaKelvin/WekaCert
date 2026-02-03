class Document {
  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.isExpirable,
    this.expiryDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String type;
  final bool isExpirable;
  final DateTime? expiryDate;
  final DateTime createdAt;
}
