import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'cloud_backup_service.dart';
import 'content_encryption_service.dart';
import 'database_service.dart';
import 'document_controller.dart';
import 'document_repository.dart';
import 'file_encryption_service.dart';
import 'local_document_service.dart';
import 'key_management_service.dart';
import 'notification_service.dart';
import 'preferences_service.dart';
import 'browser_document_controller_stub.dart'
  if (dart.library.html) 'browser_document_controller.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final PreferencesService preferences;
  late final NotificationService notifications;
  late final AuthService auth;
  late final CloudBackupService backup;
  late final ApiService api;
  late final LocalDocumentService? localVault;

  // Mobile-only — not initialized on web
  DatabaseService? database;
  DocumentRepository? repository;
  DocumentController? documents;

  Future<void> initialize() async {
    preferences = PreferencesService();
    notifications = NotificationService();
    auth = AuthService(preferences);
    api = ApiService(baseUrl: apiBaseUrl, prefs: preferences);
    final key = await KeyManagementService().getOrCreateKey();

    if (!kIsWeb) {
      final fileEncryption = FileEncryptionService(keyMaterial: key);
      backup = CloudBackupService(encryptionKey: key, api: api);
      database = DatabaseService(encryptionKey: key);
      repository = DocumentRepository(database!);
      documents = DocumentController(
        repository: repository!,
        notifications: notifications,
        preferences: preferences,
        fileEncryption: fileEncryption,
        backup: backup,
      );
      localVault = documents;
    } else {
      // Stub backup service for web — not used but prevents late errors
      backup = CloudBackupService(encryptionKey: '');
      localVault = BrowserDocumentController(
        preferences: preferences,
        encryption: ContentEncryptionService(keyMaterial: key),
        api: api,
      );
    }

    await notifications.initialize();
  }
}
