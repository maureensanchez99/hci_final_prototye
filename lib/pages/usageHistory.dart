import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageHistoryPage extends StatefulWidget {
  const UsageHistoryPage({super.key});

  @override
  State<UsageHistoryPage> createState() => _UsageHistoryPageState();
}

class _UsageHistoryPageState extends State<UsageHistoryPage> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('medication_history');
    if (historyString != null) {
      final List decoded = jsonDecode(historyString);
      setState(() {
        history = decoded.map<Map<String, dynamic>>((item) {
          return {
            'name': item['name'],
            'dosage': item['dosage'],
            'takenAt': DateTime.parse(item['takenAt']),
          };
        }).toList();
      });
      history.sort((a, b) => b['takenAt'].compareTo(a['takenAt']));
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
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
              "Usage History",
              style: TextStyle(
                fontFamily: 'Merienda',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text(
                        "No doses taken yet.",
                        style: TextStyle(fontFamily: 'Merienda', fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              "${entry['name']} (${entry['dosage']})",
                              style: const TextStyle(fontFamily: 'Merienda', fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Taken at: ${_formatDateTime(entry['takenAt'])}",
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
