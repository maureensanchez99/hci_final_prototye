import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewMedicationPage extends StatefulWidget {
  const ViewMedicationPage({super.key});

  @override
  State<ViewMedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<ViewMedicationPage> {
  List<Map<String, String>> medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
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

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medications', jsonEncode(medications));
  }

  void _editMedication(int index) {
    final med = medications[index];

    final nameController = TextEditingController(text: med['name']);
    final dosageController = TextEditingController(text: med['dosage']);
    final frequencyController = TextEditingController(text: med['frequency']);
    final quantityController = TextEditingController(text: med['quantity']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Medication", style: TextStyle(fontFamily: 'Merienda')),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Medication Name"),
                ),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: "Dosage"),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: "Frequency"),
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: "Total Quantity"),
                  keyboardType: TextInputType.number,
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
              onPressed: () {
                setState(() {
                  medications[index] = {
                    'name': nameController.text,
                    'dosage': dosageController.text,
                    'frequency': frequencyController.text,
                    'quantity': quantityController.text,
                  };
                });

                _saveMedications();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedication(int index) async {
    setState(() {
      medications.removeAt(index);
    });
    _saveMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar now empty
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // NEW TITLE IN BODY
          const Center(
            child: Text(
              "My Medications",
              style: TextStyle(
                fontFamily: "Merienda",
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: medications.isEmpty
                ? const Center(
                    child: Text(
                      "No medications added yet.",
                      style: TextStyle(fontSize: 18, fontFamily: 'Merienda'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),

                          title: Text(
                            med['name']!,
                            style: const TextStyle(
                              fontFamily: 'Merienda',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text("Dosage: ${med['dosage']}", style: const TextStyle(fontFamily: 'Merienda')),
                              Text("Frequency: ${med['frequency']}", style: const TextStyle(fontFamily: 'Merienda')),
                              Text("Total Quantity: ${med['quantity']}", style: const TextStyle(fontFamily: 'Merienda')),
                            ],
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _editMedication(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMedication(index),
                              ),
                            ],
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