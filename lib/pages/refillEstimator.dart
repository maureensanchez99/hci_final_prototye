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
  Map<String, DateTime> refillDates = {};

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('medications');

    if (saved != null) {
      final decoded = jsonDecode(saved);

      medications = (decoded as List).map<Map<String, String>>((m) {
        return {
          'name': m['name']?.toString() ?? "",
          'dosage': m['dosage']?.toString() ?? "",
          'quantity': m['quantity']?.toString() ?? "",
          'frequency': m['frequency']?.toString() ?? "",
        };
      }).toList();
    }

    _calculateRefills();
    setState(() {});
  }

  int _extractDosageNumber(String d) {
    final r = RegExp(r'\d+');
    final m = r.firstMatch(d);
    return m != null ? int.parse(m.group(0)!) : 1;
  }

  int _extractFrequencyHours(String f) {
    final r = RegExp(r'\d+');
    final m = r.firstMatch(f);
    return m != null ? int.parse(m.group(0)!) : 24;
  }

  DateTime _estimate(String name, int qty, String dosage, String freq) {
    if (qty <= 0) return DateTime.now();

    final perDose = _extractDosageNumber(dosage);
    final hours = _extractFrequencyHours(freq);

    final dosesPerDay = 24 / hours;
    final dailyUse = perDose * dosesPerDay;

    if (dailyUse == 0) return DateTime.now();

    final daysLeft = qty / dailyUse;

    return DateTime.now().add(Duration(days: daysLeft.floor()));
  }

  void _calculateRefills() {
    refillDates.clear();

    for (var m in medications) {
      final qty = int.tryParse(m['quantity'] ?? "0") ?? 0;

      refillDates[m['name']!] = _estimate(
        m['name']!,
        qty,
        m['dosage']!,
        m['frequency']!,
      );
    }
  }

  Widget _medCard(Map<String, String> med) {
    final name = med['name']!;
    final est = refillDates[name];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFF582C83), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            med['name']!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF582C83),
            ),
          ),
          const SizedBox(height: 10),

          Text("Dosage: ${med['dosage']}"),
          Text("Quantity Left: ${med['quantity']}"),
          Text("Frequency: ${med['frequency']}"),
          const SizedBox(height: 12),

          est != null
              ? Text(
                  "Refill Date: ${est.month}/${est.day}/${est.year}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDAA520),
                  ),
                )
              : const Text(
                  "Not enough data to calculate.",
                  style: TextStyle(color: Colors.red),
                ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    medications.remove(med);
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF582C83),
                ),
                child: const Text(
                  "Remove",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      appBar: AppBar(

      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Center(
              child: Text(
                "Refill Estimator",
                style: TextStyle(
                  fontFamily: "Merienda",
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Estimate When You Need Refills",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF582C83),
              ),
            ),
          ),

          Expanded(
            child: medications.isEmpty
                ? const Center(
                    child: Text(
                      "No medications found.",
                      style: TextStyle(fontSize: 17),
                    ),
                  )
                : ListView.builder(
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      return _medCard(medications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
