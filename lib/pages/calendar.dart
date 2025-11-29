import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarPage extends StatefulWidget {

  final String username;
  const CalendarPage({super.key, required this.username});

  @override
  State<CalendarPage> createState() => _CalendarState();

}

class _CalendarState extends State<CalendarPage> {
  
  DateTime today = DateTime.now();
  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });

  }

  List<Map<String, dynamic>> notifications = [];

  Map<DateTime, List<Map<String, dynamic>>> events = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<Map<String, dynamic>?> _loadMedicationFor(String medName) async {
  final prefs = await SharedPreferences.getInstance();
  final medsString = prefs.getString('medications');
  if (medsString == null) return null;

  final List decoded = jsonDecode(medsString);

  // Find matching medication entry
  for (var item in decoded) {
    if (item['name'] == medName) return item;
  }
  return null;
}


  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifsString = prefs.getString('notifications');

    if (notifsString == null) return;

    final List decoded = jsonDecode(notifsString);

    notifications = decoded.map<Map<String, dynamic>>((item) {
      return {
        'name': item['name'],
        'dosage': item['dosage'],
        'startDate': DateTime.parse(item['startDate']),
        'frequencyValue': item['frequencyValue'] ?? 1,
        'frequencyUnit': item['frequencyUnit'] ?? 'days',
        'time': TimeOfDay(
          hour: item['time']?['hour'] ?? 9,
          minute: item['time']?['minute'] ?? 0,
        ),
      };
    }).toList();

    _generateEventMap();
  }

  void _generateEventMap() async {
  events.clear();

  for (var notif in notifications) {

    // 1. Load corresponding medication data
    final med = await _loadMedicationFor(notif['name']);
    if (med == null) continue;

    // Extract quantity and dosage number
    int quantity = int.tryParse(med['quantity'] ?? "1") ?? 1;

    // Parse dosage format (e.g., "2 pills")
    int dosageNumber = 1;
    try {
      dosageNumber = int.parse(med['dosage'].split(" ").first);
    } catch (_) {}

    // How many times can user take this medication?
    int totalOccurrences = (quantity / dosageNumber).floor();
    if (totalOccurrences < 1) continue;

    DateTime next = notif['startDate'];
    int value = notif['frequencyValue'];
    String unit = notif['frequencyUnit'];

    // 2. Only generate occurrences equal to pill supply
    for (int i = 0; i < totalOccurrences; i++) {
      final dateKey = DateTime(next.year, next.month, next.day);

      events[dateKey] ??= [];
      events[dateKey]!.add(notif);

      switch (unit) {
        case 'hours':
          next = next.add(Duration(hours: value));
          break;
        case 'weeks':
          next = next.add(Duration(days: 7 * value));
          break;
        default:
          next = next.add(Duration(days: value));
      }
    }
  }

  setState(() {});
}


  List<Map<String, dynamic>> get eventsForToday {
    final lookupDay = DateTime(today.year, today.month, today.day);
    return events[lookupDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: content()
    );
  }

  Widget content() {
  return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: Column(
        children: [
          Center(
            child: TableCalendar(
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true
              ),
              selectedDayPredicate: (day)=> isSameDay(day, today),
              availableGestures: AvailableGestures.all,
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              onDaySelected:_onDaySelected,

              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return events[key] ?? [];
              },
            ),
          ),
          SizedBox(height: 10),
          Text("Selected Day: ${today.toString().split(" ")[0]}", style: const TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          Expanded(
            child: eventsForToday.isEmpty
                ? const Text("No medications scheduled for this day.")
                : ListView.builder(
                    itemCount: eventsForToday.length,
                    itemBuilder: (context, index) {
                      final med = eventsForToday[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            med['name'],
                            style: const TextStyle(
                                fontFamily: 'Merienda',
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${med['dosage']} at "
                            "${med['time'].hour.toString().padLeft(2, '0')}:"
                            "${med['time'].minute.toString().padLeft(2, '0')}",
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
}
}


