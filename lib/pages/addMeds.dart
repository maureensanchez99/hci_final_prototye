import 'package:flutter/material.dart';

class AddMedicationPage extends StatelessWidget {
  const AddMedicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Add Medication",
          style: TextStyle(
            fontFamily: 'Merienda',
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,   
        elevation: 1,                    
        iconTheme: const IconThemeData(
          color: Colors.black,           
        ),
      ),

      body: const Center(
        child: Text(
          "Add Medication to Log",
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
