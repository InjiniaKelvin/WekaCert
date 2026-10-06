import 'package:flutter/material.dart';

import '../models/document.dart';
import '../models/document_category.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';
import '../utils/date_utils.dart';
import '../widgets/document_status_badge.dart';
import 'document_detail_screen.dart';
import 'document_list_screen.dart';
import 'login_screen.dart';
import 'pin_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Document> _documents = [];
  bool _isLoading = true;
  String? _userEmail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ServiceLocator.instance.preferences.getToken();
    if (!mounted) return;
    if (token == null) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      return;
    }

    final pinEnabled = await ServiceLocator.instance.preferences.isPinEnabled();
    if (!mounted) return;
    if (pinEnabled) {
      final unlocked = await Navigator.pushNamed<bool>(
        context,
        PinScreen.routeName,
      );
      if (!mounted) return;
      if (unlocked != true) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }
    }

    _userEmail = await ServiceLocator.instance.preferences.getUserEmail();
    await _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final localController = ServiceLocator.instance.localVault;
      final docs = localController != null
          ? (await localController.fetchDocuments())
              .map((item) => item.document)
              .toList()
          : await ServiceLocator.instance.api.listDocuments();
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load documents.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ServiceLocator.instance.preferences.clearAll();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final reminderDays = 30;

    final total = _documents.length;
    final expiring = _documents.where((d) {
      if (!d.isExpirable || d.expiryDate == null) return false;
      final diff = d.expiryDate!.difference(now).inDays;
      return diff >= 0 && diff <= reminderDays;
    }).length;
    final expired = _documents.where((d) {
      if (!d.isExpirable || d.expiryDate == null) return false;
      return d.expiryDate!.isBefore(now);
    }).length;
    final valid = total - expiring - expired;

    final recent = (_documents.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('WekaCert'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, UploadScreen.routeName);
          _loadDocuments();
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            style: TextStyle(color: cs.error)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadDocuments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    children: [
                      // ── Greeting ──────────────────────────
                      Text(
                        'Welcome back${_userEmail != null ? ',\n${_userEmail!.split('@').first}' : ''}!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDate(now)} • ${total == 0 ? 'No documents yet' : '$total document${total == 1 ? '' : 's'}'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),

                      // ── Stats row ─────────────────────────
                      Row(
                        children: [
                          _StatCard(
                            label: 'Valid',
                            count: valid,
                            color: Colors.green,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'Expiring',
                            count: expiring,
                            color: Colors.orange,
                            icon: Icons.warning_amber_outlined,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'Expired',
                            count: expired,
                            color: Colors.red,
                            icon: Icons.cancel_outlined,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'Total',
                            count: total,
                            color: cs.primary,
                            icon: Icons.folder_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Quick actions ─────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.upload_file,
                              label: 'Upload Document',
                              onTap: () async {
                                await Navigator.pushNamed(
                                    context, UploadScreen.routeName);
                                _loadDocuments();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.folder_copy_outlined,
                              label: 'All Documents',
                              onTap: () async {
                                await Navigator.pushNamed(
                                    context, DocumentListScreen.routeName);
                                _loadDocuments();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Recent documents ──────────────────
                      if (recent.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Documents',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Navigator.pushNamed(
                                    context, DocumentListScreen.routeName);
                                _loadDocuments();
                              },
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final doc in recent)
                          _DocumentListTile(
                            document: doc,
                            reminderDays: reminderDays,
                          ),
                      ] else if (!_isLoading) ...[
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: cs.outlineVariant),
                              const SizedBox(height: 12),
                              Text(
                                'No documents yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap Upload to add your first document.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.outlineVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
// ── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Quick action tile ────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Document list tile ────────────────────────────────────────────────────────

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile(
      {required this.document, required this.reminderDays});

  final Document document;
  final int reminderDays;

  @override
  Widget build(BuildContext context) {
    final status = statusForExpiry(
      isExpirable: document.isExpirable,
      expiryDate: document.expiryDate,
      reminderDays: reminderDays,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(document.name),
        subtitle: Text(
            '${document.category.label} • ${labelForStatus(status)}'),
        trailing: DocumentStatusBadge(status: status),
        onTap: () => Navigator.pushNamed(
          context,
          DocumentDetailScreen.routeName,
          arguments: document.id,
        ),
      ),
    );
  }
}
