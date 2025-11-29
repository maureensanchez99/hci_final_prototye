import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../services/medication_service.dart';

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  late MedicationService _medicationService;
  late ReminderService _reminderService;

  List<Map<String, String>> _medications = [];
  List<Reminder> _reminders = [];
  Map<String, String>? _selectedMedication;
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
    _medicationService = MedicationService();
    _reminderService = ReminderService(_medicationService);
    _loadMedications();
    _loadReminders();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medsString = prefs.getString('medications');
    if (medsString != null) {
      final List decoded = jsonDecode(medsString);
      setState(() {
        _medications = decoded.map<Map<String, String>>((item) {
          return {
            'name': item['name'],
            'dosage': item['dosage'],
            'frequency': item['frequency'],
            'quantity': item['quantity'],
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReminders() async {
    final reminders = await _reminderService.getAllReminders();
    setState(() {
      _reminders = reminders;
    });
  }

  Future<void> _addReminder() async {
    if (_selectedMedication == null) {
      _showErrorDialog('Please select a medication');
      return;
    }

    final reminder = Reminder(
      id: _generateId(),
      medicationId: _selectedMedication!['name']!,
      medicationName: _selectedMedication!['name']!,
      daysBeforeRefill: _daysBeforeRefill,
      createdDate: DateTime.now(),
      notificationTime: _notificationTime,
    );

    await _reminderService.addReminder(reminder);
    await _reminderService.scheduleNotificationsForReminder(reminder);
    await _loadReminders();

    _showAddAnotherDialog();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void _showAddAnotherDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Added!'),
        content: const Text('Do you want to add another notification?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // go back
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              setState(() {
                _selectedMedication = null;
                _daysBeforeRefill = 3;
                _notificationTime = const TimeOfDay(hour: 9, minute: 0);
              });
            },
            child: const Text('Add Another'),
          ),
        ],
      ),
    );
  }

  String _generateId() {
    return 'reminder_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
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
              style: const TextStyle(fontFamily: 'Merienda', fontSize: 12),
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
                reminder.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: reminder.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () async {
                final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
                await _reminderService.updateReminder(updatedReminder);
                await _loadReminders();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _reminderService.deleteReminder(reminder.id);
                await _loadReminders();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox(),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Center(
                    child: Text(
                      'Set Up Reminder Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Merienda',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            ? const Text(
                                'No medications added yet. Please add medications first.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Merienda',
                                ),
                              )
                            : DropdownButton<Map<String, String>>(
                                value: _selectedMedication,
                                isExpanded: true,
                                items: _medications.map((med) {
                                  return DropdownMenuItem<Map<String, String>>(
                                    value: med,
                                    child: Text('${med['name']} (${med['dosage']})'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMedication = value;
                                  });
                                },
                              ),
                        const SizedBox(height: 20),
                        const Text('Reminder Presets:'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _presets.map((preset) {
                            final isSelected = _daysBeforeRefill == preset['days'];
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? Colors.green : Colors.grey[200]),
                              onPressed: () {
                                setState(() {
                                  _daysBeforeRefill = preset['days'];
                                });
                              },
                              child: Text(
                                preset['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text('Notification Time:'),
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
                                Text(_notificationTime.format(context)),
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
                            ),
                            onPressed: _addReminder,
                            child: const Text('Add Reminder'),
                          ),
                        ),
                        const SizedBox(height: 30),
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
                            ? const Text(
                                'No reminders set yet',
                                style: TextStyle(
                                  fontFamily: 'Merienda',
                                  color: Colors.grey,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _reminders.length,
                                itemBuilder: (context, index) {
                                  return _buildReminderCard(_reminders[index]);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
