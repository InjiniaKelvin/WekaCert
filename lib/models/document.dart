import 'document_category.dart';

class Document {
  Document({
    required this.id,
    required this.name,
    required this.category,
    required this.isExpirable,
    this.expiryDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DocumentCategory category;
  final bool isExpirable;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Document copyWith({
    String? id,
    String? name,
    DocumentCategory? category,
    bool? isExpirable,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isExpirable: isExpirable ?? this.isExpirable,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'isExpirable': isExpirable ? 1 : 0,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Document fromMap(Map<String, Object?> map) {
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
}
