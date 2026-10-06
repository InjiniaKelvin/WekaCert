import '../models/document_category.dart';

const documentCategories = [
  DocumentCategory.id,
  DocumentCategory.certificate,
  DocumentCategory.license,
  DocumentCategory.property,
  DocumentCategory.other,
];

const reminderDayOptions = [3, 7, 14, 30];

const pinLength = 4;

const String apiBaseUrl = 'http://localhost:3000';

const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB
