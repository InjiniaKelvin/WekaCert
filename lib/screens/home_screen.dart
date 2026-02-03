import 'package:flutter/material.dart';

import 'document_list_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WekaCert')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
        ),
      ),
    );
  }
}
