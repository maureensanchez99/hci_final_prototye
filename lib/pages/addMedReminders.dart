import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMedNotificationPage extends StatefulWidget {
  const AddMedNotificationPage({super.key});

  @override
  State<AddMedNotificationPage> createState() =>
      _AddMedNotificationPageState();
}

class _AddMedNotificationPageState
    extends State<AddMedNotificationPage> {
  List<Map<String, String>> medications = [];
  List<Map<String, dynamic>> notifications = [];
  Map<String, String>? _selectedMedication;
  String _selectedDay = 'Monday';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  final List<String> daysOfWeekOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _loadNotifications();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medsString = prefs.getString('medications');
    if (medsString != null) {
      final List decoded = jsonDecode(medsString);
      setState(() {
        medications = decoded.map<Map<String, String>>((item) {
          return {
            'name': item['name'] ?? '',
            'dosage': item['dosage'] ?? '',
            'frequency': item['frequency'] ?? 'every 1 day',
            'quantity': item['quantity'] ?? '1'
          };
        }).toList();
      });
    }
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifsString = prefs.getString('notifications');

    if (notifsString != null) {
      final List decoded = jsonDecode(notifsString);
      setState(() {
        notifications =
            decoded.map<Map<String, dynamic>>((item) {
          return {
            'name': item['name'],
            'dosage': item['dosage'],
            'startDate': DateTime.parse(item['startDate']),
            'frequencyValue': item['frequencyValue'],
            'frequencyUnit': item['frequencyUnit'],
            'time': TimeOfDay(
              hour: item['time']['hour'],
              minute: item['time']['minute'],
            ),
          };
        }).toList();
      });
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = notifications.map((notif) {
      return {
        'name': notif['name'],
        'dosage': notif['dosage'],
        'startDate':
            (notif['startDate'] as DateTime).toIso8601String(),
        'frequencyValue': notif['frequencyValue'],
        'frequencyUnit': notif['frequencyUnit'],
        'time': {
          'hour': notif['time'].hour,
          'minute': notif['time'].minute
        },
      };
    }).toList();

    await prefs.setString(
        'notifications', jsonEncode(encoded));
  }

  Map<String, dynamic> _parseFrequency(String freq) {
    final parts = freq.replaceAll("every ", "").split(" ");
    return {
      'value': int.tryParse(parts[0]) ?? 1,
      'unit': parts[1]
    };
  }

  void _addNotification() {
    if (_selectedMedication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a medication")),
      );
      return;
    }

    final freq = _parseFrequency(_selectedMedication!['frequency']!);
    int freqValue = freq['value'];
    String freqUnit = freq['unit'];

    int dayIndex = daysOfWeekOrder.indexOf(_selectedDay);
    DateTime now = DateTime.now();
    int daysUntil =
        (dayIndex - (now.weekday - 1) + 7) % 7;

    DateTime firstDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).add(Duration(days: daysUntil));

    notifications
        .removeWhere((n) => n['name'] == _selectedMedication!['name']);

    notifications.add({
      'name': _selectedMedication!['name'],
      'dosage': _selectedMedication!['dosage'],
      'startDate': firstDate,
      'frequencyValue': freqValue,
      'frequencyUnit': freqUnit,
      'time': _selectedTime,
    });

    _saveNotifications();
    _showAddAnotherDialog();
  }

  void _showAddAnotherDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notification Added!"),
        content: const Text(
            "Do you want to add another or go back?"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Go Back")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedMedication = null;
              });
            },
            child: const Text("Add Another"),
          ),
        ],
      ),
    );
  }

  List<String> _getNextTimes(DateTime start, int value, String unit) {
    List<String> list = [];
    DateTime next = start;

    for (int i = 0; i < 3; i++) {
      list.add(
          "${daysOfWeekOrder[next.weekday - 1]} (${next.month}/${next.day} ${next.hour}:${next.minute.toString().padLeft(2, '0')})");

      if (unit == "hours") {
        next = next.add(Duration(hours: value));
      } else if (unit == "weeks") {
        next = next.add(Duration(days: value * 7));
      } else {
        next = next.add(Duration(days: value));
      }
    }

    return list;
  }

  Widget _buildNotifCard(Map notif) {
    final nextTimes = _getNextTimes(
      notif['startDate'],
      notif['frequencyValue'],
      notif['frequencyUnit'],
    );

    return Card(
      child: ListTile(
        title: Text(
          "${notif['name']} (${notif['dosage']})",
          style: const TextStyle(
              fontFamily: 'Merienda',
              fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: nextTimes
              .map((e) => Text(e))
              .toList(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              notifications.remove(notif);
            });
            _saveNotifications();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medNames = notifications
        .map((n) => n['name'])
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Add Reminder Notification",
                style: TextStyle(
                  fontFamily: "Merienda",
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const Text("Select Medication:",
                style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600)),
            const SizedBox(height: 8),

            DropdownButton<Map<String, String>>(
              value: _selectedMedication,
              isExpanded: true,
              items: medications.map((med) {
                return DropdownMenuItem(
                  value: med,
                  child: Text(
                      "${med['name']} (${med['dosage']})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedMedication = value);
              },
            ),

            const SizedBox(height: 20),

            const Text("Day of Week:",
                style:
                    TextStyle(fontFamily: 'Merienda')),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedDay,
              isExpanded: true,
              items: daysOfWeekOrder
                  .map((d) => DropdownMenuItem(
                      value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedDay = v!),
            ),

            const SizedBox(height: 20),

            const Text("Time:",
                style:
                    TextStyle(fontFamily: 'Merienda')),
            const SizedBox(height: 8),

            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime);
                if (picked != null)
                  setState(() => _selectedTime = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius:
                        BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),
                    Text(_selectedTime.format(context)),
                    const Spacer(),
                    const Icon(Icons.edit)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Center(
              child: ElevatedButton(
                onPressed: _addNotification,
                child: const Text("Add Reminder"),
              ),
            ),

            const SizedBox(height: 30),

            const Text("Your Reminders:",
                style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold)),
            const SizedBox(height: 10),

            ...notifications.map((n) => _buildNotifCard(n)).toList(),
          ],
        ),
      ),
    );
  }
}
