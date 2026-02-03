import 'auth_service.dart';
import 'cloud_backup_service.dart';
import 'database_service.dart';
import 'document_controller.dart';
import 'document_repository.dart';
import 'key_management_service.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final PreferencesService preferences;
  late final NotificationService notifications;
  late final AuthService auth;
  late final CloudBackupService backup;
  late final DatabaseService database;
  late final DocumentRepository repository;
  late final DocumentController documents;

  Future<void> initialize() async {
    preferences = PreferencesService();
    notifications = NotificationService();
    auth = AuthService(preferences);
    final key = await KeyManagementService().getOrCreateKey();
    backup = CloudBackupService(encryptionKey: key);
    database = DatabaseService(encryptionKey: key);
    repository = DocumentRepository(database);
    documents = DocumentController(
      repository: repository,
      notifications: notifications,
      preferences: preferences,
      backup: backup,
    );
    await notifications.initialize();
  }
}
