import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/service_locator.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  static const routeName = '/pin';

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final AuthService _auth = ServiceLocator.instance.auth;
  final PreferencesService _preferences = ServiceLocator.instance.preferences;
  final _pinController = TextEditingController();
  int _attempts = 0;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Enter your PIN to unlock WekaCert.'),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PIN',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _attemptUnlock,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attemptUnlock() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }
    final success = await _auth.verifyPin(pin);
    if (!success) {
      _attempts += 1;
      setState(() => _error = 'Incorrect PIN. Attempts: $_attempts');
      if (_attempts >= 5) {
        await _preferences.setPinEnabled(false);
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
