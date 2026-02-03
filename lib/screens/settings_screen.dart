import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
  bool _pinEnabled = false;
  int _reminderDays = 7;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
            subtitle: const Text('Encrypted backups are stored privately.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackupInfo(context),
          ),
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
          'Sign-in integration is pending; enable when cloud setup is complete.',
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
}

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
        value: _selectedDays,
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
