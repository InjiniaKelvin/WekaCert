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
    bool clearCategory = false,
    ExpiryStatus? expiryStatus,
    bool clearExpiryStatus = false,
    bool? isExpirable,
    bool clearIsExpirable = false,
  }) {
    return DocumentFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : category ?? this.category,
      expiryStatus: clearExpiryStatus ? null : expiryStatus ?? this.expiryStatus,
      isExpirable: clearIsExpirable ? null : isExpirable ?? this.isExpirable,
    );
  }
}
