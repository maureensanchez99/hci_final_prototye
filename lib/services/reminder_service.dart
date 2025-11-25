import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import '../models/medication.dart';
import 'medication_service.dart';
import 'notification_service.dart';

class ReminderService {
  static const String _remindersKey = 'reminders';
  late SharedPreferences _prefs;
  final MedicationService medicationService;

  ReminderService(this.medicationService);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Reminder>> getAllReminders() async {
    final jsonString = _prefs.getString(_remindersKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading reminders: $e');
      return [];
    }
  }

  Future<List<Reminder>> getActiveReminders() async {
    final reminders = await getAllReminders();
    return reminders.where((r) => r.isActive).toList();
  }

  Future<Reminder?> getReminderById(String id) async {
    final reminders = await getAllReminders();
    try {
      return reminders.firstWhere((reminder) => reminder.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Reminder>> getRemindersForMedication(String medicationId) async {
    final reminders = await getAllReminders();
    return reminders.where((r) => r.medicationId == medicationId).toList();
  }

  Future<bool> hasReminderForMedication(String medicationId) async {
    final reminders = await getRemindersForMedication(medicationId);
    return reminders.isNotEmpty;
  }

  Future<void> addReminder(Reminder reminder) async {
    final reminders = await getAllReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);
  }

  Future<void> scheduleNotificationsForReminder(Reminder reminder) async {
    try {
      final medication = await medicationService.getMedicationById(reminder.medicationId);
      if (medication == null) return;
      
      final notificationService = NotificationService();
      await notificationService.scheduleReminderNotification(
        reminder: reminder,
        medication: medication,
      );
    } catch (e) {
      print('Error scheduling notification (may not be supported on this platform): $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    final reminders = await getAllReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await _saveReminders(reminders);
    }
  }

  Future<void> deleteReminder(String id) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);
    
    try {
      final notificationService = NotificationService();
      await notificationService.cancelReminderNotification(id);
    } catch (e) {
      print('Error canceling notification (may not be supported on this platform): $e');
    }
  }

  Future<void> toggleReminderStatus(String id) async {
    final reminder = await getReminderById(id);
    if (reminder != null) {
      await updateReminder(reminder.copyWith(isActive: !reminder.isActive));
    }
  }

  Future<List<ReminderNotification>> getNotificationsToBeSent() async {
    final reminders = await getActiveReminders();
    final notifications = <ReminderNotification>[];

    for (var reminder in reminders) {
      final medication =
          await medicationService.getMedicationById(reminder.medicationId);
      if (medication != null && medication.nextRefillDate != null) {
        final notificationDate = medication.nextRefillDate!
            .subtract(Duration(days: reminder.daysBeforeRefill));
        final today = DateTime.now();

        if (today.isAfter(notificationDate) &&
            (reminder.lastNotificationDate == null ||
                reminder.lastNotificationDate!.isBefore(today))) {
          notifications.add(
            ReminderNotification(
              reminder: reminder,
              medication: medication,
              notificationDate: notificationDate,
            ),
          );
        }
      }
    }

    return notifications;
  }

  Future<List<ReminderNotification>> getUrgentNotifications() async {
    final allNotifications = await getNotificationsToBeSent();
    return allNotifications.where((n) {
      final daysUntil = n.medication.nextRefillDate!.difference(DateTime.now()).inDays;
      return daysUntil <= 2;
    }).toList();
  }

  Future<void> markNotificationSent(String reminderId) async {
    final reminder = await getReminderById(reminderId);
    if (reminder != null) {
      await updateReminder(
          reminder.copyWith(lastNotificationDate: DateTime.now()));
    }
  }

  Future<void> _saveReminders(List<Reminder> reminders) async {
    final jsonList = reminders.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_remindersKey, jsonString);
  }

  Future<void> clearAllReminders() async {
    await _prefs.remove(_remindersKey);
  }
}

class ReminderNotification {
  final Reminder reminder;
  final Medication medication;
  final DateTime notificationDate;

  ReminderNotification({
    required this.reminder,
    required this.medication,
    required this.notificationDate,
  });

  String getNotificationMessage() {
    final daysUntilRefill = medication.nextRefillDate!.difference(DateTime.now()).inDays;
    return 'Time to refill ${medication.name}! Your refill is due in $daysUntilRefill days.';
  }
}
