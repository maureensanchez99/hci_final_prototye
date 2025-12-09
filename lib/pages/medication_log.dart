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

  Future<void> _markDoseTaken(String name, String dosage) async {
    final prefs = await SharedPreferences.getInstance();

    final historyString = prefs.getString("medication_history");
    List history = historyString != null ? jsonDecode(historyString) : [];

    history.add({
      "name": name,
      "dosage": dosage,
      "takenAt": DateTime.now().toIso8601String(),
    });

    await prefs.setString("medication_history", jsonEncode(history));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Dose Recorded!"),
        content: Text("You marked $name ($dosage) as taken."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _editMedication(int index) {
    final med = medications[index];

    List<String> dosageParts = med['dosage']!.split(" ");
    int? dosageNumber = int.tryParse(dosageParts[0]);
    String dosageUnit =
        dosageParts.length > 1 ? dosageParts.sublist(1).join(" ") : "";

    final nameController = TextEditingController(text: med['name']);
    final quantityController = TextEditingController(text: med['quantity']);
    final dosageUnitController = TextEditingController(text: dosageUnit);

    String freqText = med['frequency']!;
    List<String> freqParts = freqText.replaceFirst("every ", "").split(" ");
    int? frequencyAmount = int.tryParse(freqParts[0]);
    String? frequencyUnit = freqParts.length > 1 ? freqParts[1] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text("Edit Medication",
                  style: TextStyle(fontFamily: 'Merienda')),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: "Medication Name"),
                    ),
                    const SizedBox(height: 10),

                    const Text("Dosage:",
                        style: TextStyle(fontFamily: 'Merienda')),
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            value: dosageNumber,
                            decoration:
                                const InputDecoration(labelText: "Num"),
                            items: List.generate(10, (i) => i + 1)
                                .map((n) => DropdownMenuItem(
                                      value: n,
                                      child: Text(n.toString()),
                                    ))
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
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Text("Frequency:",
                        style: TextStyle(fontFamily: 'Merienda')),
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Text("every "),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            value: frequencyAmount,
                            decoration:
                                const InputDecoration(labelText: "Time"),
                            items: List.generate(24, (i) => i + 1)
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text(n.toString()),
                                  ),
                                )
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
                            decoration:
                                const InputDecoration(labelText: "Unit"),
                            items: ["minutes", "hours", "days", "weeks"]
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setStateSB(() => frequencyUnit = val),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                          labelText: "Total Quantity"),
                      keyboardType: TextInputType.number,
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  child: const Text("Save"),
                  onPressed: () {
                    setState(() {
                      medications[index] = {
                        "name": nameController.text,
                        "quantity": quantityController.text,
                        "dosage":
                            "${dosageNumber!} ${dosageUnitController.text}",
                        "frequency":
                            "every ${frequencyAmount!} ${frequencyUnit!}"
                      };
                    });
                    _saveMedications();
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
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
                      style: TextStyle(
                          fontSize: 18, fontFamily: 'Merienda'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['name']!,
                                style: const TextStyle(
                                  fontFamily: 'Merienda',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("Dosage: ${med['dosage']}",
                                  style: const TextStyle(
                                      fontFamily: 'Merienda')),
                              Text("Frequency: ${med['frequency']}",
                                  style: const TextStyle(
                                      fontFamily: 'Merienda')),
                              Text("Total Quantity: ${med['quantity']}",
                                  style: const TextStyle(
                                      fontFamily: 'Merienda')),
                              const SizedBox(height: 12),

                              // --- NEW BUTTON ---
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () => _markDoseTaken(
                                  med['name']!,
                                  med['dosage']!,
                                ),
                                child:
                                    const Text("Mark Dose as Taken"),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.green),
                                    onPressed: () =>
                                        _editMedication(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteMedication(index),
                                  ),
                                ],
                              )
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
