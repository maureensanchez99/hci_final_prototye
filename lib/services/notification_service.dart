import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication.dart';
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions asynchronously without blocking
      _requestPermissions();
      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      _initialized = true;
    }
  }

  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleReminderNotification({
    required Reminder reminder,
    required Medication medication,
  }) async {
    if (!_initialized) await initialize();
    if (medication.nextRefillDate == null) return;

    final notificationDate = medication.nextRefillDate!
        .subtract(Duration(days: reminder.daysBeforeRefill));

    final scheduledDate = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      reminder.notificationTime.hour,
      reminder.notificationTime.minute,
    );

    if (scheduledDate.isBefore(DateTime.now())) return;

    final daysUntilRefill =
        medication.nextRefillDate!.difference(scheduledDate).inDays;

    await _notifications.zonedSchedule(
      _getNotificationId(reminder.id),
      'Medication Refill Reminder',
      'Time to refill ${medication.name}! Refill needed in $daysUntilRefill day${daysUntilRefill != 1 ? 's' : ''}.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication refill reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
    );
  }

  Future<void> cancelReminderNotification(String reminderId) async {
    await _notifications.cancel(_getNotificationId(reminderId));
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication refill reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  int _getNotificationId(String reminderId) {
    return reminderId.hashCode % 2147483647;
  }
}
