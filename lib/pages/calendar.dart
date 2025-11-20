import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  final String username;
  const CalendarPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: const Center(
        child: Text(
          "Calendar Page",
          style: TextStyle(
            fontFamily: 'Merienda',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
