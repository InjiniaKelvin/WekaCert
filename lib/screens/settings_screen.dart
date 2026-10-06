import 'package:flutter/material.dart';

import '../models/backup_record.dart';
import '../models/document_version.dart';
import '../services/auth_service.dart';
import '../services/document_controller.dart';
import '../services/preferences_service.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferences = ServiceLocator.instance.preferences;
  final AuthService _auth = ServiceLocator.instance.auth;
  final DocumentController? _documents = ServiceLocator.instance.documents;
  bool _pinEnabled = false;
  int _reminderDays = 7;
  bool _isBackingUp = false;
  bool _isLoadingBackups = false;
  List<BackupRecord> _backupRecords = [];
  Map<String, String> _documentNames = {};

  bool get _canBackup =>
      ServiceLocator.instance.repository != null && _documents != null;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBackupHistory();
  }

  Future<void> _loadSettings() async {
    final pinEnabled = await _preferences.isPinEnabled();
    final reminderDays = await _preferences.getReminderDays();
    if (!mounted) return;
    setState(() {
      _pinEnabled = pinEnabled;
      _reminderDays = reminderDays;
    });
  }

  Future<void> _loadBackupHistory() async {
    final documents = _documents;
    final repository = ServiceLocator.instance.repository;
    if (documents == null || repository == null) {
      return;
    }
    setState(() => _isLoadingBackups = true);
    try {
      final docs = await repository.fetchDocuments();
      final backupRecords = await documents.fetchBackupRecords();
      final names = <String, String>{};
      for (final doc in docs) {
        names[doc.document.id] = doc.document.name;
      }
      if (!mounted) return;
      setState(() {
        _backupRecords = backupRecords;
        _documentNames = names;
      });
    } finally {
      if (mounted) setState(() => _isLoadingBackups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Require PIN on launch'),
            value: _pinEnabled,
            onChanged: (value) async {
              if (value) {
                final pin = await _promptForPin(context);
                if (pin == null) return;
                await _auth.setPin(pin);
              } else {
                await _preferences.clearPin();
              }
              if (!mounted) return;
              setState(() => _pinEnabled = value);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Reminders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Reminder threshold'),
            subtitle: Text('$_reminderDays days before expiry'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectReminderDays(context),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cloud Backup (Optional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Connect Google Drive'),
            subtitle: const Text(
              'Encrypted backups are stored privately. Available on mobile only.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackupInfo(context),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isBackingUp || !_canBackup ? null : _backupAllDocuments,
            icon: const Icon(Icons.backup),
            label: Text(_isBackingUp
                ? 'Backing up...'
                : 'Backup All Documents'),
          ),
          const SizedBox(height: 16),
          if (_canBackup) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Backup History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _isLoadingBackups ? null : _loadBackupHistory,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingBackups)
              const Center(child: CircularProgressIndicator())
            else if (_backupRecords.isEmpty)
              const ListTile(
                title: Text('No backups yet'),
                subtitle: Text('Run backup to store encrypted backup records.'),
              )
            else
              ..._backupRecords.map(
                (record) => Card(
                  child: ListTile(
                    title: Text(
                      _documentNames[record.documentId] ?? 'Document ${record.documentId}',
                    ),
                    subtitle: Text(
                      'Version ${record.versionId}\nUpdated ${record.updatedAt.toIso8601String()}',
                    ),
                    isThreeLine: true,
                    trailing: TextButton(
                      onPressed: () => _restoreBackupRecord(record),
                      child: const Text('Restore'),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectReminderDays(BuildContext context) async {
    final newValue = await showDialog<int>(
      context: context,
      builder: (context) => _ReminderDaysDialog(initialValue: _reminderDays),
    );
    if (newValue == null) return;
    await _preferences.setReminderDays(newValue);
    if (!mounted) return;
    setState(() => _reminderDays = newValue);
  }

  Future<String?> _promptForPin(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter PIN (at least $pinLength digits)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
                if (controller.text.length < pinLength) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'PIN must be at least $pinLength digits.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupInfo(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cloud Backup'),
        content: const Text(
          'Cloud backups will encrypt documents before uploading. '
          'This backup path is currently available on mobile only. '
          'Sign-in integration for cloud providers is still pending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupAllDocuments() async {
    final repository = ServiceLocator.instance.repository;
    final documents = _documents;
    if (repository == null || documents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup is available on mobile only.'),
        ),
      );
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      final docs = await repository.fetchDocuments();
      int backed = 0;
      for (final doc in docs) {
        for (final version in doc.versions) {
          final result = await documents.backupVersion(version);
          if (result != null) backed++;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backed up $backed version(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
      await _loadBackupHistory();
    }
  }

  Future<void> _restoreBackupRecord(BackupRecord record) async {
    final documents = _documents;
    if (documents == null) return;
    final repository = ServiceLocator.instance.repository;
    if (repository == null) return;

    final doc = await repository.fetchDocument(record.documentId);
    if (doc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document no longer exists locally.')),
      );
      return;
    }

    final latestLocalVersion = doc.versions.isNotEmpty ? doc.versions.first : null;
    if (latestLocalVersion != null &&
        latestLocalVersion.updatedAt.isAfter(record.updatedAt)) {
      final choice = await _showConflictDialog(
        localVersion: latestLocalVersion,
        backupRecord: record,
      );
      if (choice != _ConflictChoice.restoreBackup) {
        return;
      }
    }

    final success = await documents.restoreBackupRecord(record, doc.document);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Backup restored successfully.'
            : 'Backup restore unavailable.'),
      ),
    );
    await _loadBackupHistory();
  }

  Future<_ConflictChoice?> _showConflictDialog({
    required DocumentVersion localVersion,
    required BackupRecord backupRecord,
  }) {
    return showDialog<_ConflictChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup conflict'),
        content: Text(
          'The local version (${localVersion.updatedAt.toIso8601String()}) is newer than the backup (${backupRecord.updatedAt.toIso8601String()}). What should happen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ConflictChoice.keepLocal),
            child: const Text('Keep Local'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _ConflictChoice.restoreBackup,
            ),
            child: const Text('Restore Backup'),
          ),
        ],
      ),
    );
  }
}

enum _ConflictChoice { keepLocal, restoreBackup }

class _ReminderDaysDialog extends StatefulWidget {
  const _ReminderDaysDialog({required this.initialValue});

  final int initialValue;

  @override
  State<_ReminderDaysDialog> createState() => _ReminderDaysDialogState();
}

class _ReminderDaysDialogState extends State<_ReminderDaysDialog> {
  late int _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reminder days'),
      content: DropdownButtonFormField<int>(
        initialValue: _selectedDays,
        items: reminderDayOptions
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text('$value days'),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedDays = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedDays),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
