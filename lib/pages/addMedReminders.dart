import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMedNotificationPage extends StatefulWidget {
  const AddMedNotificationPage({super.key});

  @override
  State<AddMedNotificationPage> createState() => _AddMedNotificationPageState();
}

class _AddMedNotificationPageState extends State<AddMedNotificationPage> {
  List<Map<String, String>> medications = [];
  List<Map<String, dynamic>> notifications = [];

  Map<String, String>? _selectedMedication;
  String _selectedDay = 'Monday';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  final List<String> daysOfWeekOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
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
            'quantity': item['quantity'] ?? '1',
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
        notifications = decoded.map<Map<String, dynamic>>((item) {
          return {
            'name': item['name'],
            'dosage': item['dosage'],
            'startDate': item['startDate'] != null
                ? DateTime.parse(item['startDate'])
                : DateTime.now(),
            'frequencyValue': item['frequencyValue'] ?? 1,
            'frequencyUnit': item['frequencyUnit'] ?? 'days',
            'time': TimeOfDay(
              hour: item['time']?['hour'] ?? 9,
              minute: item['time']?['minute'] ?? 0,
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
        'startDate': (notif['startDate'] as DateTime).toIso8601String(),
        'frequencyValue': notif['frequencyValue'],
        'frequencyUnit': notif['frequencyUnit'],
        'time': {'hour': notif['time'].hour, 'minute': notif['time'].minute},
      };
    }).toList();
    await prefs.setString('notifications', jsonEncode(encoded));
  }

  // Parse frequency string like "every 2 days" or "every 8 hours"
  Map<String, dynamic> _parseFrequency(String freqString) {
    final parts = freqString.toLowerCase().replaceAll('every', '').trim().split(' ');
    if (parts.length >= 2) {
      int value = int.tryParse(parts[0]) ?? 1;
      String unit = parts[1];
      if (unit.endsWith('s') == false) unit += 's'; // normalize to plural
      return {'value': value, 'unit': unit};
    }
    return {'value': 1, 'unit': 'days'};
  }

  void _addNotification() {
    if (_selectedMedication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a medication")));
      return;
    }

    // Pull frequency info from selected medication
    final freqData = _parseFrequency(_selectedMedication!['frequency']!);
    int freqValue = freqData['value'];
    String freqUnit = freqData['unit'];

    // Calculate first notification date based on selected day
    int startDayIndex = daysOfWeekOrder.indexOf(_selectedDay);
    DateTime today = DateTime.now();
    int daysUntilStart = (startDayIndex - (today.weekday - 1) + 7) % 7;
    DateTime firstDate = DateTime(
      today.year,
      today.month,
      today.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).add(Duration(days: daysUntilStart));

    // Remove old notifications for this medication
    notifications.removeWhere((n) => n['name'] == _selectedMedication!['name']);

    notifications.add({
      'name': _selectedMedication!['name']!,
      'dosage': _selectedMedication!['dosage']!,
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
        title: const Text('Notification Added!'),
        content: const Text('Do you want to add another notification or go back?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedMedication = null;
                _selectedDay = 'Monday';
                _selectedTime = const TimeOfDay(hour: 9, minute: 0);
              });
            },
            child: const Text('Add Another'),
          ),
        ],
      ),
    );
  }

  List<String> _getNextThreeTimes(DateTime start, int value, String unit) {
    List<String> nextTimes = [];
    DateTime next = start;

    for (int i = 0; i < 3; i++) {
      nextTimes.add("${daysOfWeekOrder[next.weekday - 1]} (${next.month}/${next.day} ${next.hour.toString().padLeft(2,'0')}:${next.minute.toString().padLeft(2,'0')})");

      switch (unit) {
        case 'hours':
          next = next.add(Duration(hours: value));
          break;
        case 'days':
          next = next.add(Duration(days: value));
          break;
        case 'weeks':
          next = next.add(Duration(days: 7 * value));
          break;
        default:
          next = next.add(Duration(days: value));
      }
    }

    return nextTimes;
  }

  Widget _buildNotificationCard(String medName) {
    final notif = notifications.firstWhere((n) => n['name'] == medName);
    final dosage = notif['dosage'];
    final nextTimes = _getNextThreeTimes(notif['startDate'], notif['frequencyValue'], notif['frequencyUnit']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text("$medName ($dosage)",
            style: const TextStyle(fontFamily: 'Merienda', fontWeight: FontWeight.w600)),
        subtitle: Text(nextTimes.join(', ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: () => _editNotification(medName)),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteNotification(medName)),
          ],
        ),
      ),
    );
  }

  void _editNotification(String medName) {
    // Editing logic remains similar, pulling frequency from medication
  }

  void _deleteNotification(String medName) {
    setState(() {
      notifications.removeWhere((n) => n['name'] == medName);
    });
    _saveNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueMedNames = notifications.map((n) => n['name'] as String).toSet().toList();
    uniqueMedNames.sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const SizedBox.shrink(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Medication:",
                style: TextStyle(fontFamily: 'Merienda', fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            medications.isEmpty
                ? const Text("No medications added. Please add medications first.",
                    style: TextStyle(color: Colors.grey))
                : DropdownButton<Map<String, String>>(
                    value: _selectedMedication,
                    isExpanded: true,
                    items: medications.map((med) {
                      return DropdownMenuItem(
                          value: med, child: Text("${med['name']} (${med['dosage']})"));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedMedication = value),
                  ),
            const SizedBox(height: 20),
            const Text("Day of the Week:", style: TextStyle(fontFamily: 'Merienda')),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedDay,
              isExpanded: true,
              items: daysOfWeekOrder.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (value) { if(value!=null) setState(()=>_selectedDay=value); },
            ),
            const SizedBox(height: 20),
            const Text("Notification Time:", style: TextStyle(fontFamily: 'Merienda')),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.access_time, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Text(_selectedTime.format(context)),
                  const Spacer(),
                  const Icon(Icons.edit, color: Colors.grey),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addNotification,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)),
                child: const Text("Add Notification"),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Existing Notifications",
                style: TextStyle(fontFamily: 'Merienda', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            uniqueMedNames.isEmpty
                ? const Text("No notifications yet", style: TextStyle(color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: uniqueMedNames.length,
                    itemBuilder: (context, index) =>
                        _buildNotificationCard(uniqueMedNames[index]),
                  ),
          ],
        ),
      ),
    );
  }
}
