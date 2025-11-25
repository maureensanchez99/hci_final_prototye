import 'package:flutter/material.dart';
import 'medication.dart';
import 'usage.dart';
import 'addMeds.dart';
import 'reminder.dart';
import 'refill.dart';

class LogPage extends StatelessWidget {
  final String username;
  const LogPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Homepage",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 30),

            _menuButton(
              context,
              "View Medication Log",
              const ViewMedicationLogPage(),
            ),
            const SizedBox(height: 20),

            _menuButton(
              context,
              "Add medication to log",
              const AddMedicationPage(),
            ),
            const SizedBox(height: 20),

            _menuButton(
              context,
              "Usage History",
              const UsageHistoryPage(),
            ),
            const SizedBox(height: 20),
            
            _menuButton(
              context,
              "Add reminder notifications",
              const AddReminderPage(),
            ),
            const SizedBox(height: 20),

            _menuButton(
              context,
              "Refill Estimator",
              const RefillEstimatorPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String text, Widget page) {
    return SizedBox(
      width: 260,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Merienda',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
