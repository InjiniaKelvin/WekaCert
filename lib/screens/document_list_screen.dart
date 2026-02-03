import 'package:flutter/material.dart';

import 'document_detail_screen.dart';

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  static const routeName = '/documents';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DocumentListTile(
            title: 'National ID',
            subtitle: 'ID • Valid',
            statusColor: Colors.green,
          ),
          DocumentListTile(
            title: 'Driver License',
            subtitle: 'License • Expiring soon',
            statusColor: Colors.orange,
          ),
          DocumentListTile(
            title: 'Land Title',
            subtitle: 'Property • Permanent',
            statusColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: CircleAvatar(
          radius: 6,
          backgroundColor: statusColor,
        ),
        onTap: () => Navigator.pushNamed(
          context,
          DocumentDetailScreen.routeName,
        ),
      ),
    );
  }
}
