import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RefillEstimatorPage extends StatefulWidget {
  const RefillEstimatorPage({super.key});

  @override
  State<RefillEstimatorPage> createState() => _RefillEstimatorPageState();
}

class _RefillEstimatorPageState extends State<RefillEstimatorPage> {
  List<Map<String, String>> medications = [];
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final medsString = prefs.getString('medications');
    if (medsString != null) {
      final List decoded = jsonDecode(medsString);
      medications = decoded.map<Map<String, String>>((item) {
        return {
          'name': item['name'],
          'dosage': item['dosage'],
          'quantity': item['quantity'],
        };
      }).toList();
    }

    final historyString = prefs.getString('medication_history');
    if (historyString != null) {
      final List decoded = jsonDecode(historyString);
      history = decoded.map<Map<String, dynamic>>((item) {
        return {
          'name': item['name'],
          'dosage': item['dosage'],
          'takenAt': DateTime.parse(item['takenAt']),
        };
      }).toList();
    }

    setState(() {});
  }

  String _estimateRefill(String medName, String totalQuantityStr, String dosageStr) {
    int totalQuantity = int.tryParse(totalQuantityStr) ?? 0;
    int dosage = int.tryParse(dosageStr) ?? 1;

    final takenCount = history.where((h) => h['name'] == medName).length;

    final remainingDoses = totalQuantity - takenCount * dosage;
    if (remainingDoses <= 0) return "Refill needed now";

    final medHistory = history.where((h) => h['name'] == medName).toList();
    if (medHistory.isEmpty) return "Usage not started";

    medHistory.sort((a, b) => b['takenAt'].compareTo(a['takenAt']));
    final lastTaken = medHistory.first['takenAt'] as DateTime;

    List<DateTime> dates = medHistory.map((h) => h['takenAt'] as DateTime).toList();
    if (dates.length < 2) return "Next refill in unknown days";

    int totalInterval = 0;
    for (int i = 1; i < dates.length; i++) {
      totalInterval += dates[i - 1].difference(dates[i]).inDays;
    }
    int avgInterval = totalInterval ~/ (dates.length - 1);
    if (avgInterval <= 0) avgInterval = 1;

    DateTime estimatedRefillDate = lastTaken.add(Duration(days: avgInterval * (remainingDoses ~/ dosage)));

    return "${estimatedRefillDate.month}/${estimatedRefillDate.day}/${estimatedRefillDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Refill Estimator",
              style: TextStyle(
                fontFamily: 'Merienda',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: medications.isEmpty
                  ? const Center(
                      child: Text(
                        "No medications available.",
                        style: TextStyle(fontFamily: 'Merienda'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: medications.length,
                      itemBuilder: (context, index) {
                        final med = medications[index];
                        final refillDate = _estimateRefill(med['name']!, med['quantity']!, med['dosage']!);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              "${med['name']} (${med['dosage']})",
                              style: const TextStyle(fontFamily: 'Merienda', fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Estimated refill: $refillDate",
                              style: const TextStyle(fontFamily: 'Merienda'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
