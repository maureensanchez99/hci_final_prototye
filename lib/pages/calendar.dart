import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
            ),
          ),
          Text("Selected Day: ${today.toString().split(" ")[0]}"),
        ],
      ),
    );
}
}


