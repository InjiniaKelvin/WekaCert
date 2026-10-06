import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/document.dart';
import '../utils/date_utils.dart';

class NotificationService {
  static Future<void>? _initFuture;
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    _initFuture ??= Future<void>(() => tz.initializeTimeZones());
    await _initFuture;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    await _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
    await _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleExpiryReminder({
    required Document document,
    required int reminderDays,
  }) async {
    if (!document.isExpirable || document.expiryDate == null) {
      return;
    }
    final status = statusForExpiry(
      isExpirable: document.isExpirable,
      expiryDate: document.expiryDate,
      reminderDays: reminderDays,
    );
    if (status == ExpiryDisplayStatus.expired) {
      return;
    }
    final scheduledDate = document.expiryDate!.subtract(
      Duration(days: reminderDays),
    );
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiring-docs',
        'Expiring Documents',
        channelDescription: 'Reminders for expiring documents',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      document.id.hashCode,
      'Document expiring soon',
      '${document.name} expires on ${formatDate(document.expiryDate!)}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String documentId) async {
    await _plugin.cancel(documentId.hashCode);
  }
}
