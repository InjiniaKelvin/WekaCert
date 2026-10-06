import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/document.dart';
import '../models/document_category.dart';
import '../models/document_version.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/document_status_badge.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key});

  static const routeName = '/documents/detail';

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isAddingVersion = false;
  Document? _document;
  List<DocumentVersion> _versions = [];
  bool _isLoading = true;
  String? _error;
  int _reminderDays = 7;
  bool get _usesLocalController => ServiceLocator.instance.localVault != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) _load();
  }

  Future<void> _load() async {
    final documentId =
        ModalRoute.of(context)?.settings.arguments as String?;
    if (documentId == null) {
      setState(() {
        _error = 'No document ID provided.';
        _isLoading = false;
      });
      return;
    }

    final days = await ServiceLocator.instance.preferences.getReminderDays();
    try {
      if (!mounted) return;
      if (_usesLocalController) {
        final data = await ServiceLocator.instance.localVault!.fetchDocument(documentId);
        if (data == null) {
          setState(() {
            _error = 'Document not found.';
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _document = data.document;
          _versions = data.versions;
          _reminderDays = days;
          _isLoading = false;
        });
        return;
      }

      final data = await ServiceLocator.instance.api.getDocument(documentId);
      setState(() {
        _document = data['document'] as Document;
        _versions = data['versions'] as List<DocumentVersion>;
        _reminderDays = days;
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
        _error = 'Failed to load document.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        actions: [
          if (_document != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editDocument(_document!);
                if (value == 'delete') _deleteDocument(_document!.id);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Document')),
                PopupMenuItem(value: 'delete', child: Text('Delete Document')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final doc = _document!;
    final status = statusForExpiry(
      isExpirable: doc.isExpirable,
      expiryDate: doc.expiryDate,
      reminderDays: _reminderDays,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(doc.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Category: ${doc.category.label}'),
        const SizedBox(height: 8),
        Row(
          children: [
            DocumentStatusBadge(status: status),
            if (doc.expiryDate != null) ...[
              const SizedBox(width: 12),
              Text('Expires: ${formatDate(doc.expiryDate!)}'),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text('Created: ${formatDate(doc.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: 32),
        // Action buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _isAddingVersion ? null : () => _addNewVersion(doc),
              icon: const Icon(Icons.upload_file),
              label:
                  Text(_isAddingVersion ? 'Uploading…' : 'Add New Version'),
            ),
          ],
        ),
        const Divider(height: 32),
        // Latest version
        if (_versions.isNotEmpty) ...[
          Card(
            child: ListTile(
              title: const Text('Latest Version'),
              subtitle: Text(
                'Uploaded: ${formatDate(_versions.first.createdAt)}'
                '${_versions.first.note != null ? '\n${_versions.first.note}' : ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open file',
                onPressed: () => _openFile(doc.id, _versions.first),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Version History (${_versions.length})',
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _versions.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${_versions.length - i}'),
              ),
              title: Text('Version ${_versions.length - i}'),
              subtitle: Text(
                '${formatDate(_versions[i].createdAt)}'
                '${_versions[i].note != null ? ' — ${_versions[i].note}' : ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open file',
                onPressed: () => _openFile(doc.id, _versions[i]),
              ),
            ),
          ),
      ],
    );
  }

  void _openFile(String docId, DocumentVersion version) {
    if (_usesLocalController) {
      ServiceLocator.instance.localVault!.openFile(version.filePath);
      return;
    }
    final url = ServiceLocator.instance.api.fileUrl(docId, version.id);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Download File'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewVersion(Document document) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;

    if (_usesLocalController && !kIsWeb && file.path == null) return;
    if (!_usesLocalController && file.bytes == null) return;

    if (file.bytes != null && file.bytes!.length > maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File exceeds 50 MB limit.')),
        );
      }
      return;
    }

    final note = await _promptForNote();

    setState(() => _isAddingVersion = true);
    try {
      if (_usesLocalController) {
        await ServiceLocator.instance.localVault!.addVersion(
          document: document,
          fileBytes: file.bytes,
          filePath: file.path,
          fileName: file.name,
          note: note,
        );
        final refreshed = await ServiceLocator.instance.localVault!.fetchDocument(document.id);
        if (!mounted) return;
        setState(() {
          _document = refreshed?.document ?? _document;
          _versions = refreshed?.versions ?? _versions;
          _isAddingVersion = false;
        });
      } else {
        final version = await ServiceLocator.instance.api.uploadFile(
          document.id,
          file.bytes!,
          file.name,
          note: note,
        );
        if (!mounted) return;
        setState(() {
          _versions = [version, ..._versions];
          _isAddingVersion = false;
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New version added.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isAddingVersion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAddingVersion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed.')),
      );
    }
  }

  Future<String?> _promptForNote() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Version Note'),
        content: TextField(
          controller: ctrl,
          decoration:
              const InputDecoration(hintText: 'Optional note for this version'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip')),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDocument(Document document) async {
    final result = await showDialog<Document>(
      context: context,
      builder: (_) => _EditDocumentDialog(document: document),
    );
    if (result == null || !mounted) return;
    try {
      if (_usesLocalController) {
        await ServiceLocator.instance.localVault!.updateDocument(result);
        setState(() => _document = result);
        return;
      }
      final updated = await ServiceLocator.instance.api.updateDocument(
        document.id,
        name: result.name,
        category: result.category.name,
        isExpirable: result.isExpirable,
        expiryDate: result.isExpirable ? result.expiryDate : null,
        clearExpiry: !result.isExpirable,
      );
      if (!mounted) return;
      setState(() => _document = updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _deleteDocument(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
            'This will permanently delete the document and all its versions.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (_usesLocalController) {
        await ServiceLocator.instance.localVault!.deleteDocument(id);
      } else {
        await ServiceLocator.instance.api.deleteDocument(id);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}

// ── Helper: open URL in new tab (web only) ────────────────────────────────────

// ignore: non_constant_identifier_names, camel_case_types
void import_html_openUrl(String url) {
  // Uses dart:html indirectly via conditional import or js interop if needed.
  // For now, we use a platform-safe approach at runtime for web.
}

// ── Edit-document dialog ──────────────────────────────────────────────────────

class _EditDocumentDialog extends StatefulWidget {
  const _EditDocumentDialog({required this.document});

  final Document document;

  @override
  State<_EditDocumentDialog> createState() => _EditDocumentDialogState();
}

class _EditDocumentDialogState extends State<_EditDocumentDialog> {
  late final TextEditingController _nameController;
  late DocumentCategory _category;
  late bool _isExpirable;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.name);
    _category = widget.document.category;
    _isExpirable = widget.document.isExpirable;
    _expiryDate = widget.document.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Document'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DocumentCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: documentCategories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Expires'),
              value: _isExpirable,
              onChanged: (v) => setState(() {
                _isExpirable = v;
                if (!v) _expiryDate = null;
              }),
            ),
            if (_isExpirable)
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Select expiry date'
                    : formatDate(_expiryDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _expiryDate ?? now.add(const Duration(days: 365)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365 * 30)),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              widget.document.copyWith(
                name: name,
                category: _category,
                isExpirable: _isExpirable,
                expiryDate: _isExpirable ? _expiryDate : null,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
