import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({super.key});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();

  Future<void> _saveMedication() async {
    if (_nameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _frequencyController.text.isEmpty ||
        _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? medsString = prefs.getString('medications');

    List<Map<String, String>> medications = [];

    if (medsString != null) {
      final List decoded = jsonDecode(medsString);
      medications = decoded.map<Map<String, String>>((item) {
        return {
          'name': item['name'].toString(),
          'dosage': item['dosage'].toString(),
          'quantity': item['quantity'].toString(),
          'frequency': item['frequency'].toString(),
        };
      }).toList();
    }

    // Add new medication
    medications.add({
      'name': _nameController.text,
      'dosage': _dosageController.text,
      'quantity': _quantityController.text,
      'frequency': _frequencyController.text,
    });

    await prefs.setString('medications', jsonEncode(medications));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Medication saved")),
    );

    _nameController.clear();
    _dosageController.clear();
    _quantityController.clear();
    _frequencyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: const Text(
                  "Add Medication to Log",
                  style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Name
              const Text("1. Name of Medication:",
                  style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "E.g., Ibuprofen, Vitamin D, Amoxicillin",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Dosage
              const Text("2. Dosage:",
                  style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              TextField(
                controller: _dosageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "How many pills/capsules you take each dosage",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Frequency
              const Text("3. Frequency: ",
                  style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              TextField(
                controller: _frequencyController,
                decoration: InputDecoration(
                  hintText: "E.g., twice a day, every 8 hours, once nightly",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quantity
              const Text("4. Total Quantity:",
                  style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Total pills/capsules currently in your bottle",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Save Medication",
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: "Merienda",
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}