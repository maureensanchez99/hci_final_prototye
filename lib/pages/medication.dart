import 'package:flutter/material.dart';

class ViewMedicationLogPage extends StatelessWidget {
  const ViewMedicationLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "View Medication Log",
              style: TextStyle(
                fontFamily: 'Merienda',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Current medications will be displayed here.",
              style: TextStyle(
                fontFamily: 'Merienda',
                fontSize: 20,
                color: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}
