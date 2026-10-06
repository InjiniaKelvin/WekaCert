import 'package:flutter/material.dart';

import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_filter.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/document_status_badge.dart';
import 'document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  static const routeName = '/documents';

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _searchController = TextEditingController();
  DocumentFilter _filter = const DocumentFilter();
  int _reminderDays = 7;
  List<Document> _documents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDocuments();
  }

  Future<void> _loadPreferences() async {
    final days = await ServiceLocator.instance.preferences.getReminderDays();
    if (!mounted) return;
    setState(() => _reminderDays = days);
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final localController = ServiceLocator.instance.localVault;
      final docs = localController != null
          ? (await localController.fetchDocuments())
              .map((item) => item.document)
              .toList()
          : await ServiceLocator.instance.api.listDocuments();
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load documents.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Document> get _filtered {
    final q = _filter.searchQuery.toLowerCase();
    return _documents.where((doc) {
      if (q.isNotEmpty &&
          !doc.name.toLowerCase().contains(q) &&
          !doc.category.label.toLowerCase().contains(q)) {
        return false;
      }
      if (_filter.category != null && doc.category != _filter.category) {
        return false;
      }
      if (_filter.isExpirable != null &&
          doc.isExpirable != _filter.isExpirable) {
        return false;
      }
      if (_filter.expiryStatus != null) {
        final status = statusForExpiry(
          isExpirable: doc.isExpirable,
          expiryDate: doc.expiryDate,
          reminderDays: _reminderDays,
        );
        final filterStatus = toFilterStatus(status);
        if (filterStatus != _filter.expiryStatus) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
      body: Column(
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
              onChanged: (value) =>
                  setState(() => _filter = _filter.copyWith(searchQuery: value)),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error)),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _loadDocuments,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDocuments,
                        child: filtered.isEmpty
                            ? const Center(child: Text('No documents found.'))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final doc = filtered[index];
                                  final status = statusForExpiry(
                                    isExpirable: doc.isExpirable,
                                    expiryDate: doc.expiryDate,
                                    reminderDays: _reminderDays,
                                  );
                                  return DocumentListTile(
                                    document: doc,
                                    status: status,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showModalBottomSheet<DocumentFilter>(
      context: context,
      builder: (_) => _FilterSheet(current: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }
}
class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.status,
  });

  final Document document;
  final ExpiryDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${document.category.label} • ${labelForStatus(status)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(document.name),
        subtitle: Text(subtitle),
        trailing: DocumentStatusBadge(status: status),
        onTap: () => Navigator.pushNamed(
          context,
          DocumentDetailScreen.routeName,
          arguments: document.id,
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
            initialValue: _filter.category,
            items: [
              const DropdownMenuItem<DocumentCategory?>(
                  value: null, child: Text('All')),
              ...documentCategories.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c.label))),
            ],
            onChanged: (v) => setState(() {
              _filter = _filter.copyWith(
                  category: v, clearCategory: v == null);
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpiryStatus?>(
            decoration: const InputDecoration(labelText: 'Expiry status'),
            initialValue: _filter.expiryStatus,
            items: const [
              DropdownMenuItem<ExpiryStatus?>(value: null, child: Text('All')),
              DropdownMenuItem(value: ExpiryStatus.valid, child: Text('Valid')),
              DropdownMenuItem(
                  value: ExpiryStatus.expiringSoon,
                  child: Text('Expiring soon')),
              DropdownMenuItem(
                  value: ExpiryStatus.expired, child: Text('Expired')),
              DropdownMenuItem(
                  value: ExpiryStatus.permanent, child: Text('Permanent')),
            ],
            onChanged: (v) => setState(() {
              _filter = _filter.copyWith(
                  expiryStatus: v, clearExpiryStatus: v == null);
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool?>(
            decoration: const InputDecoration(labelText: 'Type'),
            initialValue: _filter.isExpirable,
            items: const [
              DropdownMenuItem<bool?>(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Expirable')),
              DropdownMenuItem(value: false, child: Text('Permanent')),
            ],
            onChanged: (v) => setState(() {
              _filter = _filter.copyWith(
                  isExpirable: v, clearIsExpirable: v == null);
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
