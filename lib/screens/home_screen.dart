import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'pin_screen.dart';
import 'document_list_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = ServiceLocator.instance.auth;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final pinEnabled = await ServiceLocator.instance.preferences.isPinEnabled();
    if (!pinEnabled) return;
    final authenticated = await _auth.authenticateWithBiometrics();
    if (!mounted) return;
    if (authenticated) return;
    setState(() => _isLocked = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WekaCert')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLocked ? _buildLockedView(context) : _buildUnlockedView(),
      ),
    );
  }

  Widget _buildUnlockedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Securely store your documents and track expiries.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pushNamed(
            context,
            DocumentListScreen.routeName,
          ),
          child: const Text('View Documents'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.pushNamed(
            context,
            UploadScreen.routeName,
          ),
          child: const Text('Upload Document'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            SettingsScreen.routeName,
          ),
          child: const Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildLockedView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, size: 48),
        const SizedBox(height: 12),
        const Text('Unlock WekaCert to continue.'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _unlockWithPin,
          child: const Text('Enter PIN'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            final success = await _auth.authenticateWithBiometrics();
            if (!mounted) return;
            setState(() => _isLocked = !success);
          },
          child: const Text('Use biometrics'),
        ),
      ],
    );
  }

  Future<void> _unlockWithPin() async {
    final success = await Navigator.pushNamed<bool>(
      context,
      PinScreen.routeName,
    );
    if (!mounted) return;
    if (success == true) {
      setState(() => _isLocked = false);
    }
  }
}
