import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/reminder.dart';
import '../services/medication_service.dart';
import '../services/reminder_service.dart';
import 'dart:math';

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final MedicationService _medicationService = MedicationService();
  late ReminderService _reminderService;
  List<Medication> _medications = [];
  List<Reminder> _reminders = [];
  Medication? _selectedMedication;
  int _daysBeforeRefill = 3;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  final List<Map<String, dynamic>> _presets = [
    {'label': '1 day', 'days': 1},
    {'label': '3 days', 'days': 3},
    {'label': '1 week', 'days': 7},
    {'label': '2 weeks', 'days': 14},
  ];

  @override
  void initState() {
    super.initState();
    _reminderService = ReminderService(_medicationService);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _medicationService.initialize();
    await _reminderService.initialize();
    _loadMedicationsAndReminders();
  }

  Future<void> _loadMedicationsAndReminders() async {
    final medications = await _medicationService.getAllMedications();
    final reminders = await _reminderService.getAllReminders();

    setState(() {
      _medications = medications;
      _reminders = reminders;
      _isLoading = false;
    });
  }

  Future<void> _addReminder() async {
    if (_selectedMedication == null) {
      _showErrorDialog('Please select a medication');
      return;
    }

    if (_selectedMedication!.nextRefillDate == null) {
      _showErrorDialog('This medication does not have a refill date set');
      return;
    }

    final hasReminder = await _reminderService.hasReminderForMedication(_selectedMedication!.id);
    if (hasReminder) {
      _showErrorDialog('This medication already has a reminder set');
      return;
    }

    final reminder = Reminder(
      id: _generateId(),
      medicationId: _selectedMedication!.id,
      medicationName: _selectedMedication!.name,
      daysBeforeRefill: _daysBeforeRefill,
      createdDate: DateTime.now(),
      notificationTime: _notificationTime,
    );

    await _reminderService.addReminder(reminder);
    await _reminderService.scheduleNotificationsForReminder(reminder);
    await _loadMedicationsAndReminders();

    if (!mounted) return;
    _showSuccessDialog('Reminder added successfully!');
    setState(() {
      _selectedMedication = null;
      _daysBeforeRefill = 3;
      _notificationTime = const TimeOfDay(hour: 9, minute: 0);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _generateId() {
    return 'reminder_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add Reminder Notifications',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Up Refill Reminders',
                    style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Select Medication:',
                    style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _medications.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'No medications added yet. Please add medications first.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Merienda',
                            ),
                          ),
                        )
                      : DropdownButtonFormField<Medication>(
                          value: _selectedMedication,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          items: _medications
                              .map((med) => DropdownMenuItem(
                                    value: med,
                                    child: Text(
                                      '${med.name} (${med.dosage})',
                                      style: const TextStyle(
                                        fontFamily: 'Merienda',
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMedication = value;
                            });
                          },
                        ),
                  const SizedBox(height: 25),

                  const Text(
                    'Reminder Presets:',
                    style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _presets.map((preset) {
                      final isSelected = _daysBeforeRefill == preset['days'];
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.green
                              : Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _daysBeforeRefill = preset['days'];
                          });
                        },
                        child: Text(
                          preset['label'],
                          style: TextStyle(
                            fontFamily: 'Merienda',
                            color: isSelected
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Custom Days:',
                    style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _daysBeforeRefill.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '$_daysBeforeRefill days',
                          onChanged: (value) {
                            setState(() {
                              _daysBeforeRefill = value.toInt();
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_daysBeforeRefill days',
                          style: const TextStyle(
                            fontFamily: 'Merienda',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Notification Time:',
                    style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _notificationTime,
                      );
                      if (time != null) {
                        setState(() {
                          _notificationTime = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.blue[600]),
                          const SizedBox(width: 12),
                          Text(
                            _notificationTime.format(context),
                            style: const TextStyle(
                              fontFamily: 'Merienda',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit, color: Colors.grey[600], size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addReminder,
                      child: const Text(
                        'Add Reminder',
                        style: TextStyle(
                          fontFamily: 'Merienda',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'Active Reminders',
                    style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _reminders.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'No reminders set yet',
                            style: TextStyle(
                              fontFamily: 'Merienda',
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _reminders[index];
                            return _buildReminderCard(reminder);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: reminder.isActive ? Colors.green[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.notifications,
            color: reminder.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          reminder.medicationName,
          style: const TextStyle(
            fontFamily: 'Merienda',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notify ${reminder.daysBeforeRefill} day${reminder.daysBeforeRefill != 1 ? 's' : ''} before refill',
              style: const TextStyle(
                fontFamily: 'Merienda',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  reminder.notificationTime.format(context),
                  style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                reminder.isActive
                    ? Icons.toggle_on
                    : Icons.toggle_off,
                color: reminder.isActive
                    ? Colors.green
                    : Colors.grey,
              ),
              onPressed: () async {
                await _reminderService
                    .toggleReminderStatus(reminder.id);
                await _loadMedicationsAndReminders();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _reminderService.deleteReminder(reminder.id);
                await _loadMedicationsAndReminders();
              },
            ),
          ],
        ),
      ),
    );
  }
}
