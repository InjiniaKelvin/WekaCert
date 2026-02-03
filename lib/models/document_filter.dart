import 'document_category.dart';

enum ExpiryStatus { valid, expiringSoon, expired, permanent }

class DocumentFilter {
  const DocumentFilter({
    this.searchQuery = '',
    this.category,
    this.expiryStatus,
    this.isExpirable,
  });

  final String searchQuery;
  final DocumentCategory? category;
  final ExpiryStatus? expiryStatus;
  final bool? isExpirable;

  DocumentFilter copyWith({
    String? searchQuery,
    DocumentCategory? category,
    ExpiryStatus? expiryStatus,
    bool? isExpirable,
  }) {
    return DocumentFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      expiryStatus: expiryStatus ?? this.expiryStatus,
      isExpirable: isExpirable ?? this.isExpirable,
    );
  }
}
