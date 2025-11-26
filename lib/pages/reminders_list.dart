import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/reminder.dart';
import '../services/medication_service.dart';
import '../services/reminder_service.dart';

class RemindersListPage extends StatefulWidget {
  const RemindersListPage({super.key});

  @override
  State<RemindersListPage> createState() => _RemindersListPageState();
}

class _RemindersListPageState extends State<RemindersListPage> {
  final MedicationService _medicationService = MedicationService();
  late ReminderService _reminderService;
  List<Reminder> _reminders = [];
  Map<String, Medication?> _medicationMap = {};
  bool _isLoading = true;
  int _urgentCount = 0;

  @override
  void initState() {
    super.initState();
    _reminderService = ReminderService(_medicationService);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _medicationService.initialize();
    await _reminderService.initialize();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await _reminderService.getActiveReminders();
    final medicationMap = <String, Medication?>{};

    for (var reminder in reminders) {
      medicationMap[reminder.medicationId] =
          await _medicationService.getMedicationById(reminder.medicationId);
    }

    final urgentNotifications =
        await _reminderService.getUrgentNotifications();

    setState(() {
      _reminders = reminders;
      _medicationMap = medicationMap;
      _urgentCount = urgentNotifications.length;
      _isLoading = false;
    });

    if (urgentNotifications.isNotEmpty) {
      _showUrgentNotification(urgentNotifications.length);
    }
  }

  void _showUrgentNotification(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ $count medication(s) need refilling soon!',
          style: const TextStyle(
            fontFamily: 'Merienda',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Reminders Overview',
          style: TextStyle(
            fontFamily: 'Merienda',
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: _reminders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reminders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0 && _urgentCount > 0) {
                          return _buildUrgentBanner();
                        }
                        final reminderIndex = index - (_urgentCount > 0 ? 1 : 0);
                        final reminder = _reminders[reminderIndex];
                        final medication =
                            _medicationMap[reminder.medicationId];
                        return _buildReminderCard(reminder, medication);
                      },
                    ),
            ),
    );
  }

  Widget _buildUrgentBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urgent Refills Needed',
                  style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                Text(
                  '$_urgentCount medication(s) need refilling within 2 days',
                  style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active reminders',
            style: TextStyle(
              fontFamily: 'Merienda',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add reminders to get notified about medication refills',
            style: TextStyle(
              fontFamily: 'Merienda',
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, Medication? medication) {
    String refillInfo = 'Refill date not set';
    int? daysUntilRefill;
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;

    if (medication != null && medication.nextRefillDate != null) {
      daysUntilRefill =
          medication.nextRefillDate!.difference(DateTime.now()).inDays;
      final notifyDate =
          medication.nextRefillDate!.subtract(Duration(days: reminder.daysBeforeRefill));

      if (DateTime.now().isAfter(notifyDate)) {
        if (daysUntilRefill <= 0) {
          statusColor = Colors.red;
          statusIcon = Icons.error;
          refillInfo = 'URGENT: Refill needed NOW';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.warning;
          refillInfo =
              'URGENT: Refill needed in $daysUntilRefill day${daysUntilRefill != 1 ? 's' : ''}';
        }
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        final daysUntilNotification =
            notifyDate.difference(DateTime.now()).inDays;
        refillInfo = 'Refill in $daysUntilNotification day${daysUntilNotification != 1 ? 's' : ''}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.medicationName,
                          style: const TextStyle(
                            fontFamily: 'Merienda',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (medication != null)
                          Text(
                            '${medication.dosage} • ${medication.frequency}',
                            style: TextStyle(
                              fontFamily: 'Merienda',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          daysUntilRefill != null && daysUntilRefill > 0
                              ? '${daysUntilRefill}d'
                              : 'Now',
                          style: TextStyle(
                            fontFamily: 'Merienda',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refillInfo,
                        style: TextStyle(
                          fontFamily: 'Merienda',
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.notifications,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notify ${reminder.daysBeforeRefill} day${reminder.daysBeforeRefill != 1 ? 's' : ''} before refill',
                      style: TextStyle(
                        fontFamily: 'Merienda',
                        fontSize: 13,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                  if (medication?.quantity != null)
                    Text(
                      'Stock: ${medication?.quantity}',
                      style: TextStyle(
                        fontFamily: 'Merienda',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
