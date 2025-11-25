import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'landing_page.dart';
import '../main.dart';

class TitlePage extends StatelessWidget {
  const TitlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Text(
              'MediMate',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 80),  
            
            Padding(
              padding: const EdgeInsets.only(bottom: 150.0),
              child: ElevatedButton(
                onPressed: () async {
                  // Initialize services when button is pressed
                  if (!kIsWeb) {
                    // Skip service initialization on Android for now
                    try {
                      await initializeServices();
                    } catch (e) {
                      print('Service initialization error: $e');
                    }
                  } else {
                    await initializeServices();
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LandingPage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(

                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 6,
                ),
                child: const Text(
                  'Start Logging',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}