import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/document_category.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  static const routeName = '/upload';

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  DocumentCategory? _selectedCategory;
  bool _isExpirable = true;
  DateTime? _expiryDate;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Selected file (web-compatible — bytes only)
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  int? _selectedFileSize;
  String? _selectedFilePath;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Document name ─────────────────────
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Document Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Category ──────────────────────────
            DropdownButtonFormField<DocumentCategory>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: documentCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              initialValue: _selectedCategory,
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),

            // ── Expiry toggle ─────────────────────
            SwitchListTile(
              title: const Text('This document expires'),
              value: _isExpirable,
              onChanged: (v) => setState(() {
                _isExpirable = v;
                if (!v) _expiryDate = null;
              }),
            ),
            if (_isExpirable) ...[
              const SizedBox(height: 8),
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Select Expiry Date'
                    : 'Expiry: ${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: cs.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: () => _pickExpiryDate(context),
              ),
            ],
            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // ── File picker ───────────────────────
            OutlinedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedBytes == null
                  ? 'Choose File (any type, max 50 MB)'
                  : 'Change File'),
            ),

            // ── File preview ──────────────────────
            if (_selectedBytes != null && _selectedFileName != null) ...[
              const SizedBox(height: 12),
              _FilePreviewCard(
                fileName: _selectedFileName!,
                fileSize: _selectedFileSize ?? _selectedBytes!.length,
              ),
            ],

            const SizedBox(height: 24),

            // ── Save ──────────────────────────────
            FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : (_selectedBytes != null ? _saveDocument : null),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Uploading…' : 'Save Document'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 30)),
    );
    if (picked != null && mounted) setState(() => _expiryDate = picked);
  }

  Future<void> _chooseFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;

    final bytes = file.bytes;
    if (bytes != null && bytes.length > maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File exceeds 50 MB limit.')),
        );
      }
      return;
    }
    setState(() {
      _selectedBytes = bytes;
      _selectedFileName = file.name;
      _selectedFileSize = file.size;
      _selectedFilePath = file.path;
    });
  }

  Future<void> _saveDocument() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a file.')),
      );
      return;
    }
    if (_isExpirable && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final localController = ServiceLocator.instance.localVault;
      final api = ServiceLocator.instance.api;

      if (localController != null) {
        await localController.addDocument(
          name: _nameController.text.trim(),
          category: _selectedCategory!,
          isExpirable: _isExpirable,
          expiryDate: _isExpirable ? _expiryDate : null,
          fileBytes: _selectedBytes,
          filePath: _selectedFilePath,
          fileName: _selectedFileName!,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_nameController.text.trim()} saved locally!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        return;
      }

      // 1. Create document record
      final doc = await api.createDocument(
        name: _nameController.text.trim(),
        category: _selectedCategory!.name,
        isExpirable: _isExpirable,
        expiryDate: _isExpirable ? _expiryDate : null,
      );

      // 2. Upload the file
      await api.uploadFile(
        doc.id,
        _selectedBytes!,
        _selectedFileName!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${doc.name} saved successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Upload failed. Please try again.'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
// ── File preview card ────────────────────────────────────────────────────────

class _FilePreviewCard extends StatelessWidget {
  const _FilePreviewCard({required this.fileName, required this.fileSize});

  final String fileName;
  final int fileSize;

  String get _formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get _icon {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 36, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_formattedSize,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green.shade600),
        ],
      ),
    );
  }
}
