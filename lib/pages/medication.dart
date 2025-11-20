import 'package:flutter/material.dart';

class ViewMedicationLogPage extends StatelessWidget {
  const ViewMedicationLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          "View Medication Log",
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
