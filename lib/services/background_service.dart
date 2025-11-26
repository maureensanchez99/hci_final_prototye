import 'package:workmanager/workmanager.dart';
import 'medication_service.dart';
import 'reminder_service.dart';
import 'notification_service.dart';

const String checkRemindersTask = 'checkRemindersTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final medicationService = MedicationService();
      final notificationService = NotificationService();
      
      await medicationService.initialize();
      await notificationService.initialize();
      
      final reminderService = ReminderService(medicationService);
      await reminderService.initialize();

      final notificationsToBeSent = await reminderService.getNotificationsToBeSent();

      for (var notification in notificationsToBeSent) {
        await notificationService.scheduleReminderNotification(
          reminder: notification.reminder,
          medication: notification.medication,
        );

        await reminderService.markNotificationSent(notification.reminder.id);
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await schedulePeriodicCheck();
  }

  Future<void> schedulePeriodicCheck() async {
    await Workmanager().registerPeriodicTask(
      'medication-reminder-check',
      checkRemindersTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
