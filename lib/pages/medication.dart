import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewMedicationLogPage extends StatefulWidget {
  const ViewMedicationLogPage({super.key});

  @override
  State<ViewMedicationLogPage> createState() => _ViewMedicationLogPageState();
}

class _ViewMedicationLogPageState extends State<ViewMedicationLogPage> {
  List<Map<String, String>> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? medsString = prefs.getString('medications');

    if (medsString != null) {
      final List decoded = jsonDecode(medsString);
      _medications = decoded.map<Map<String, String>>((item) {
        return {
          'name': item['name'].toString(),
          'dosage': item['dosage'].toString(),
          'quantity': item['quantity'].toString(),
        };
      }).toList();
      setState(() {});
    }
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medications', jsonEncode(_medications));
  }

  Future<void> _editMedication(int index) async {
    final nameController =
        TextEditingController(text: _medications[index]['name']);
    final dosageController =
        TextEditingController(text: _medications[index]['dosage']);
    final quantityController =
        TextEditingController(text: _medications[index]['quantity']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Medication"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Medication Name"),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: "Dosage"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _medications[index] = {
                  'name': nameController.text,
                  'dosage': dosageController.text,
                  'quantity': quantityController.text,
                };
              });
              _saveMedications();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Medication"),
        content: const Text("Are you sure you want to delete this medication?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _medications.removeAt(index);
      });
      _saveMedications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Medication Log",
          style: TextStyle(
            fontFamily: 'Merienda',
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _medications.isEmpty
            ? const Center(
                child: Text(
                  "No medications saved yet.",
                  style: TextStyle(
                    fontFamily: 'Merienda',
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _medications.length,
                itemBuilder: (context, index) {
                  final med = _medications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        med['name'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Merienda',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Dosage: ${med['dosage']}\nQuantity: ${med['quantity']}",
                        style: const TextStyle(
                          fontFamily: 'Merienda',
                          fontSize: 16,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
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
    );
  }
}