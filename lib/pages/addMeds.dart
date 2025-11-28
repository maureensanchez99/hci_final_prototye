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
  final TextEditingController _quantityController = TextEditingController();

  // Dosage
  int? _dosageNumber;
  final TextEditingController _dosageAmountController = TextEditingController();

  // Frequency
  int? _frequencyAmount;
  String? _frequencyUnit;

  Future<void> _saveMedication() async {
    if (_nameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _dosageNumber == null ||
        _dosageAmountController.text.isEmpty ||
        _frequencyAmount == null ||
        _frequencyUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final dosage = "${_dosageNumber!} ${_dosageAmountController.text}";
    final frequency = "every ${_frequencyAmount!} ${_frequencyUnit!}";

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

    medications.add({
      'name': _nameController.text,
      'dosage': dosage,
      'quantity': _quantityController.text,
      'frequency': frequency,
    });

    await prefs.setString('medications', jsonEncode(medications));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Medication Saved!",
            style: TextStyle(fontFamily: "Merienda"),
          ),
          content: const Text(
            "Would you like to add another medication or go back?",
            style: TextStyle(fontFamily: "Merienda"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                _nameController.clear();
                _quantityController.clear();
                _dosageAmountController.clear();

                setState(() {
                  _dosageNumber = null;
                  _frequencyAmount = null;
                  _frequencyUnit = null;
                });
              },
              child: const Text(
                "Add Another",
                style: TextStyle(color: Colors.green),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context);
              },
              child: const Text("Go Back"),
            ),
          ],
        );
      },
    );
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
              const Center(
                child: Text(
                  "Add Medication to Log",
                  style: TextStyle(
                      fontFamily: 'Merienda',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
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
                  hintText: "e.g., Ibuprofen",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Dosage
              const Text("2. Dosage:", style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _dosageNumber,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        labelText: "Num",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: List.generate(10, (i) => i + 1)
                          .map((n) => DropdownMenuItem(value: n, child: Text("$n")))
                          .toList(),
                      onChanged: (value) => setState(() => _dosageNumber = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _dosageAmountController,
                      decoration: InputDecoration(
                        hintText: "pills, mL, etc.",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Frequency
              const Text("3. Frequency:", style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("every", style: TextStyle(fontSize: 16, fontFamily: 'Merienda')),
                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _frequencyAmount,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        labelText: "Time",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: List.generate(24, (i) => i + 1)
                          .map((n) => DropdownMenuItem(value: n, child: Text("$n")))
                          .toList(),
                      onChanged: (value) => setState(() => _frequencyAmount = value),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _frequencyUnit,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        labelText: "Unit",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ["minutes", "hours", "days", "weeks"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (value) => setState(() => _frequencyUnit = value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quantity
              const Text("4. Total Quantity:", style: TextStyle(fontSize: 18, fontFamily: 'Merienda')),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "total amount of medication in bottle",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Medication",
                      style: TextStyle(fontSize: 18, fontFamily: "Merienda", color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
