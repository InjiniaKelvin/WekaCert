enum DocumentCategory { id, certificate, license, property, other }

extension DocumentCategoryLabel on DocumentCategory {
  String get label {
    switch (this) {
      case DocumentCategory.id:
        return 'ID';
      case DocumentCategory.certificate:
        return 'Certificate';
      case DocumentCategory.license:
        return 'License';
      case DocumentCategory.property:
        return 'Property';
      case DocumentCategory.other:
        return 'Other';
    }
  }
}
