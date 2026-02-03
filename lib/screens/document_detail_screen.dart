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
  bool _isRestoring = false;

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
                    Text('Expiry: ${formatDate(data.document.expiryDate!)}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isRestoring
                        ? null
                        : () => _restoreBackup(data.document.id),
                    child: Text(
                      _isRestoring ? 'Restoring...' : 'Restore from Backup',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data.versions.isNotEmpty)
                    Card(
                      child: ListTile(
                        title: const Text('Latest Version'),
                        subtitle: Text(
                          'Uploaded: ${formatDate(data.versions.first.updatedAt)}',
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
                  for (var index = 0; index < data.versions.length; index++)
                    Card(
                      child: ListTile(
                        title: Text(
                          'Version ${data.versions.length - index}',
                        ),
                        subtitle: Text(
                          data.versions[index].note ?? 'No notes added yet.',
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

  Future<void> _restoreBackup(String documentId) async {
    setState(() => _isRestoring = true);
    final document = await _controller.fetchDocument(documentId);
    if (document != null) {
      await _controller.restoreLatestBackup(document.document);
    }
    if (!mounted) return;
    setState(() => _isRestoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup restore complete.')),
    );
  }
}
