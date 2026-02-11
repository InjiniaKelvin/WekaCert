import 'package:flutter/material.dart';

import '../models/document_category.dart';
import 'package:file_picker/file_picker.dart';

import '../services/document_controller.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  static const routeName = '/upload';

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final DocumentController _controller = ServiceLocator.instance.documents;
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  DocumentCategory? _selectedCategory;
  bool _isExpirable = true;
  DateTime? _expiryDate;
  bool _isSaving = false;
  String? _filePath;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            DropdownButtonFormField<DocumentCategory>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: documentCategories
                  .map((category) => DropdownMenuItem<DocumentCategory>(
                        value: category,
                        child: Text(category.label),
                      ))
                  .toList(),
              value: _selectedCategory,
              validator: (value) => value == null ? 'Required' : null,
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('This document expires'),
            value: _isExpirable,
            onChanged: (value) => setState(() {
              _isExpirable = value;
              if (!_isExpirable) {
                _expiryDate = null;
              }
            }),
          ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (!_isExpirable) return null;
                if (value == null || value.trim().isEmpty) return 'Required';
                return DateTime.tryParse(value) == null
                    ? 'Use YYYY-MM-DD'
                    : null;
              },
              onChanged: (value) {
                setState(() => _expiryDate = DateTime.tryParse(value));
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _chooseFile,
              child: Text(_filePath == null ? 'Choose File' : 'File Selected'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _saveDocument,
              child: Text(_isSaving ? 'Saving...' : 'Save Document'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    setState(() => _filePath = path);
  }

  Future<void> _saveDocument() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a file.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await _controller.addDocument(
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      isExpirable: _isExpirable,
      expiryDate: _isExpirable ? _expiryDate : null,
      filePath: _filePath!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }
}
