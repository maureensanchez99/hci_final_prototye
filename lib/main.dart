import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'pages/title_page.dart';
import 'services/medication_service.dart';
import 'services/reminder_service.dart';
import 'services/notification_service.dart';

final medicationService = MedicationService();
late final reminderService = ReminderService(medicationService);
final notificationService = NotificationService();

bool _servicesInitialized = false;

Future<void> initializeServices() async {
  if (_servicesInitialized) return;
  
  try {
    await medicationService.initialize();
    await reminderService.initialize();
    if (!kIsWeb) {
      await notificationService.initialize();
    }
    _servicesInitialized = true;
  } catch (e) {
    print('Error initializing services: $e');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TitlePage(),
    );
  }
}