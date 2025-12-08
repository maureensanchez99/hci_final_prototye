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

  // --- Parse dosage: e.g. "2 pills" ---
  List<String> dosageParts = med['dosage']!.split(" ");
  int? dosageNumber = int.tryParse(dosageParts[0]);
  String dosageUnit = dosageParts.length > 1 ? dosageParts.sublist(1).join(" ") : "";

  final nameController = TextEditingController(text: med['name']);
  final quantityController = TextEditingController(text: med['quantity']);
  final dosageUnitController = TextEditingController(text: dosageUnit);

  // --- Parse frequency: e.g. "every 6 hours" ---
  String frequencyText = med['frequency']!;
  List<String> freqParts = frequencyText.replaceFirst("every ", "").split(" ");
  int? frequencyAmount = int.tryParse(freqParts[0]);
  String? frequencyUnit = freqParts.length > 1 ? freqParts[1] : null;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          title: const Text("Edit Medication",
              style: TextStyle(fontFamily: 'Merienda')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Medication Name"),
                ),
                const SizedBox(height: 10),

                // Dosage (dropdown + text)
                const Text("Dosage:", style: TextStyle(fontFamily: 'Merienda')),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: dosageNumber,
                        decoration: const InputDecoration(labelText: "Num"),
                        items: List.generate(10, (i) => i + 1)
                            .map((n) => DropdownMenuItem(
                                value: n, child: Text(n.toString())))
                            .toList(),
                        onChanged: (val) =>
                            setStateSB(() => dosageNumber = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: dosageUnitController,
                        decoration: const InputDecoration(
                            labelText: "Unit (pills, mL, etc.)"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Frequency Row
                const Text("Frequency:", style: TextStyle(fontFamily: 'Merienda')),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text("every "),
                    const SizedBox(width: 5),

                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: frequencyAmount,
                        decoration: const InputDecoration(labelText: "Time"),
                        items: List.generate(24, (i) => i + 1)
                            .map((n) => DropdownMenuItem(
                                value: n, child: Text(n.toString())))
                            .toList(),
                        onChanged: (val) =>
                            setStateSB(() => frequencyAmount = val),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: frequencyUnit,
                        decoration: const InputDecoration(labelText: "Unit"),
                        items: ["minutes", "hours", "days", "weeks"]
                            .map((u) => DropdownMenuItem(
                                value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) =>
                            setStateSB(() => frequencyUnit = val),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Quantity
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
                child: const Text("Cancel", style: TextStyle(color: Colors.red))
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                if (dosageNumber == null ||
                    dosageUnitController.text.trim().isEmpty ||
                    frequencyAmount == null ||
                    frequencyUnit == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                setState(() {
                  medications[index] = {
                    'name': nameController.text,
                    'quantity': quantityController.text,
                    'dosage':
                        "${dosageNumber!} ${dosageUnitController.text.trim()}",
                    'frequency':
                        "every ${frequencyAmount!} ${frequencyUnit!}",
                  };
                });

                _saveMedications();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      });
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

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