import 'package:flutter/material.dart';
import 'log.dart';
import 'calendar.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _selectedIndex = 0;

  final String username = "Guest";

  late final List<Widget> _pages = [
    LogPage(username: username),        // UPDATED
    CalendarPage(username: username),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _selectedIndex = 0; 
          });
        },
        backgroundColor: Colors.green,
        label: const Text(
          "Go to Log",
          style: TextStyle(
            fontFamily: 'Merienda',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.list_alt, color: Colors.white),
      ),
    );
  }
}
