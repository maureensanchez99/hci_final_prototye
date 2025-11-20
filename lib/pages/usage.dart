import 'package:flutter/material.dart';

class UsageHistoryPage extends StatelessWidget {
  const UsageHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          "Usage History",
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
