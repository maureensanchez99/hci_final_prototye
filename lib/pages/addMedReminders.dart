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
            'name': item['name'],
            'dosage': item['dosage'],
            'frequency': item['frequency'],
            'quantity': item['quantity'],
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
            'day': item['day'],
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
        'day': notif['day'],
        'time': {'hour': notif['time'].hour, 'minute': notif['time'].minute},
      };
    }).toList();
    await prefs.setString('notifications', jsonEncode(encoded));
  }

  void _addNotification() {
    if (_selectedMedication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a medication")));
      return;
    }

    final newNotif = {
      'name': _selectedMedication!['name']!,
      'dosage': _selectedMedication!['dosage']!,
      'day': _selectedDay,
      'time': _selectedTime,
    };

    setState(() {
      notifications.add(newNotif);
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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
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

  void _editNotification(int index) {
    final notif = notifications[index];

    TimeOfDay tempTime = notif['time'];
    String tempDay = notif['day'];
    Map<String, String>? tempSelectedMedication;

    if (medications.isNotEmpty) {
      tempSelectedMedication = medications.firstWhere(
        (med) => med['name'] == notif['name'],
        orElse: () => medications[0],
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Notification", style: TextStyle(fontFamily: 'Merienda')),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Medication:", style: TextStyle(fontFamily: 'Merienda')),
                  const SizedBox(height: 8),
                  medications.isEmpty
                      ? const Text(
                          "No medications available. Please add a medication first.",
                          style: TextStyle(color: Colors.grey),
                        )
                      : DropdownButton<Map<String, String>>(
                          value: tempSelectedMedication,
                          isExpanded: true,
                          items: medications.map((med) {
                            return DropdownMenuItem(
                              value: med,
                              child: Text("${med['name']} (${med['dosage']})"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() => tempSelectedMedication = value);
                          },
                        ),
                  const SizedBox(height: 20),
                  const Text("Day of the Week:", style: TextStyle(fontFamily: 'Merienda')),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: tempDay,
                    isExpanded: true,
                    items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempDay = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Notification Time:", style: TextStyle(fontFamily: 'Merienda')),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: tempTime);
                      if (picked != null) setDialogState(() => tempTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.blue[600]),
                          const SizedBox(width: 12),
                          Text(tempTime.format(context)),
                          const Spacer(),
                          const Icon(Icons.edit, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  if (tempSelectedMedication != null) {
                    setState(() {
                      notifications[index] = {
                        'name': tempSelectedMedication!['name']!,
                        'dosage': tempSelectedMedication!['dosage']!,
                        'day': tempDay,
                        'time': tempTime,
                      };
                    });
                    _saveNotifications();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    _saveNotifications();
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text("${notif['name']} (${notif['dosage']})",
            style: const TextStyle(fontFamily: 'Merienda', fontWeight: FontWeight.w600)),
        subtitle: Text("${notif['day']} at ${notif['time'].format(context)}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _editNotification(index)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNotification(index)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black), // back arrow only
        title: const SizedBox.shrink(), // no title
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
              items: [
                'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
              ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
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
            notifications.isEmpty
                ? const Text("No notifications yet", style: TextStyle(color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotificationCard(notifications[index], index),
                  ),
          ],
        ),
      ),
    );
  }
}