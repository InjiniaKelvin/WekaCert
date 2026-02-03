import 'package:flutter/material.dart';

import '../models/document_filter.dart';
import '../models/document_with_versions.dart';
import '../services/document_controller.dart';
import '../services/service_locator.dart';
import '../utils/date_utils.dart';
import '../utils/constants.dart';
import '../widgets/document_status_badge.dart';
import 'document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  static const routeName = '/documents';

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentController _controller = ServiceLocator.instance.documents;
  final _searchController = TextEditingController();
  DocumentFilter _filter = const DocumentFilter();
  int _reminderDays = 7;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _controller.loadDocuments();
  }

  Future<void> _loadPreferences() async {
    final days = await ServiceLocator.instance.preferences.getReminderDays();
    if (!mounted) return;
    setState(() => _reminderDays = days);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentWithVersions>>(
        stream: _controller.documentsStream,
        builder: (context, snapshot) {
          final docs = snapshot.data ?? [];
          return FutureBuilder<List<DocumentWithVersions>>(
            future: _controller.filterDocuments(docs, _filter, _reminderDays),
            builder: (context, filteredSnapshot) {
              final filteredDocs = filteredSnapshot.data ?? [];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search documents',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {
                        _filter = _filter.copyWith(searchQuery: value);
                      }),
                    ),
                  ),
                  Expanded(
                    child: filteredSnapshot.connectionState ==
                            ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : filteredDocs.isEmpty
                        ? const Center(
                            child: Text('No documents found.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final item = filteredDocs[index];
                              final status = statusForExpiry(
                                isExpirable: item.document.isExpirable,
                                expiryDate: item.document.expiryDate,
                                reminderDays: _reminderDays,
                              );
                              return DocumentListTile(
                                document: item,
                                status: status,
                              );
                            },
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

  Future<void> _openFilters(BuildContext context) async {
    final result = await showModalBottomSheet<DocumentFilter>(
      context: context,
      builder: (_) => _FilterSheet(current: _filter),
    );
    if (result != null) {
      setState(() => _filter = result);
    }
  }
}

class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.status,
  });

  final DocumentWithVersions document;
  final ExpiryDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${document.document.category.label} • ${labelForStatus(status)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(document.document.name),
        subtitle: Text(subtitle),
        trailing: DocumentStatusBadge(status: status),
        onTap: () => Navigator.pushNamed(
          context,
          DocumentDetailScreen.routeName,
          arguments: document.document.id,
        ),
      ),
    );
  }

}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current});

  final DocumentFilter current;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DocumentFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          DropdownButtonFormField<DocumentCategory?>(
            decoration: const InputDecoration(labelText: 'Category'),
            value: _filter.category,
            items: [
              const DropdownMenuItem<DocumentCategory?>(
                value: null,
                child: Text('All'),
              ),
              ...documentCategories.map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _filter = _filter.copyWith(
                category: value,
                clearCategory: value == null,
              );
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpiryStatus?>(
            decoration: const InputDecoration(labelText: 'Expiry status'),
            value: _filter.expiryStatus,
            items: const [
              DropdownMenuItem<ExpiryStatus?>(
                value: null,
                child: Text('All'),
              ),
              DropdownMenuItem(
                value: ExpiryStatus.valid,
                child: Text('Valid'),
              ),
              DropdownMenuItem(
                value: ExpiryStatus.expiringSoon,
                child: Text('Expiring soon'),
              ),
              DropdownMenuItem(
                value: ExpiryStatus.expired,
                child: Text('Expired'),
              ),
              DropdownMenuItem(
                value: ExpiryStatus.permanent,
                child: Text('Permanent'),
              ),
            ],
            onChanged: (value) => setState(() {
              _filter = _filter.copyWith(
                expiryStatus: value,
                clearExpiryStatus: value == null,
              );
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool?>(
            decoration: const InputDecoration(labelText: 'Type'),
            value: _filter.isExpirable,
            items: const [
              DropdownMenuItem<bool?>(
                value: null,
                child: Text('All'),
              ),
              DropdownMenuItem(value: true, child: Text('Expirable')),
              DropdownMenuItem(value: false, child: Text('Permanent')),
            ],
            onChanged: (value) => setState(() {
              _filter = _filter.copyWith(
                isExpirable: value,
                clearIsExpirable: value == null,
              );
            }),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, _filter),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
