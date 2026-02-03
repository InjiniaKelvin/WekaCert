import 'package:flutter/material.dart';

import '../models/document_with_versions.dart';
import '../services/document_controller.dart';
import '../services/service_locator.dart';
import '../utils/date_utils.dart';
import '../widgets/document_status_badge.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key});

  static const routeName = '/documents/detail';

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final DocumentController _controller = ServiceLocator.instance.documents;

  @override
  Widget build(BuildContext context) {
    final documentId = ModalRoute.of(context)?.settings.arguments as String?;
    if (documentId == null) {
      return const Scaffold(
        body: Center(child: Text('Document not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: FutureBuilder<DocumentWithVersions?>(
        future: _controller.fetchDocument(documentId),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data == null) {
            return const Center(child: Text('Document not found.'));
          }
          return FutureBuilder<int>(
            future: ServiceLocator.instance.preferences.getReminderDays(),
            builder: (context, reminderSnapshot) {
              final days = reminderSnapshot.data ?? 7;
              final status = statusForExpiry(
                isExpirable: data.document.isExpirable,
                expiryDate: data.document.expiryDate,
                reminderDays: days,
              );
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    data.document.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Category: ${data.document.category.label}'),
                  const SizedBox(height: 8),
                  DocumentStatusBadge(status: status),
                  if (data.document.expiryDate != null)
                    Text(
                      'Expiry: ${data.document.expiryDate!.toLocal()}'
                          .split(' ')[0],
                    ),
                  const SizedBox(height: 16),
                  if (data.versions.isNotEmpty)
                    Card(
                      child: ListTile(
                        title: const Text('Latest Version'),
                        subtitle: Text(
                          'Uploaded: ${data.versions.first.createdAt.toLocal()}'
                              .split(' ')[0],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('Version History'),
                  const SizedBox(height: 8),
                  ...data.versions.map(
                    (version) => Card(
                      child: ListTile(
                        title: Text('Version ${version.id.substring(0, 6)}'),
                        subtitle: Text(
                          version.note ?? 'No notes added yet.',
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
