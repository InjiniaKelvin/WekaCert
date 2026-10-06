import 'document.dart';
import 'document_version.dart';

class DocumentWithVersions {
  DocumentWithVersions({required this.document, required this.versions});

  final Document document;
  final List<DocumentVersion> versions;
}
