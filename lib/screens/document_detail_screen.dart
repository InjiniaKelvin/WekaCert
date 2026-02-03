import 'package:flutter/material.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key});

  static const routeName = '/documents/detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'National ID',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Category: ID'),
          const Text('Status: Valid'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Latest Version'),
              subtitle: const Text('Uploaded: Feb 3, 2026'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Version History'),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('Version 2'),
              subtitle: Text('Note: Renewal uploaded'),
            ),
          ),
          const Card(
            child: ListTile(
              title: Text('Version 1'),
              subtitle: Text('Note: Original document'),
            ),
          ),
        ],
      ),
    );
  }
}
