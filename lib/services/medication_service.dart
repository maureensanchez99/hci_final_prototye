import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

class MedicationService {
  static const String _medicationsKey = 'medications';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Medication>> getAllMedications() async {
    final jsonString = _prefs.getString(_medicationsKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Medication.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading medications: $e');
      return [];
    }
  }

  Future<Medication?> getMedicationById(String id) async {
    final medications = await getAllMedications();
    try {
      return medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Medication>> getMedicationsNeedingRefill() async {
    final medications = await getAllMedications();
    final now = DateTime.now();
    return medications.where((med) {
      if (med.nextRefillDate == null) return false;
      return med.nextRefillDate!.isBefore(now.add(const Duration(days: 7)));
    }).toList();
  }

  Future<List<Medication>> getLowStockMedications(int threshold) async {
    final medications = await getAllMedications();
    return medications.where((med) => med.quantity <= threshold).toList();
  }

  Future<void> addMedication(Medication medication) async {
    final medications = await getAllMedications();
    medications.add(medication);
    await _saveMedications(medications);
  }

  Future<void> updateMedication(Medication medication) async {
    final medications = await getAllMedications();
    final index = medications.indexWhere((med) => med.id == medication.id);
    if (index != -1) {
      medications[index] = medication;
      await _saveMedications(medications);
    }
  }

  Future<void> deleteMedication(String id) async {
    final medications = await getAllMedications();
    medications.removeWhere((med) => med.id == id);
    await _saveMedications(medications);
  }

  Future<void> updateMedicationQuantity(String id, int newQuantity) async {
    final medication = await getMedicationById(id);
    if (medication != null) {
      await updateMedication(medication.copyWith(quantity: newQuantity));
    }
  }

  Future<void> updateRefillDate(String id, DateTime refillDate) async {
    final medication = await getMedicationById(id);
    if (medication != null) {
      await updateMedication(medication.copyWith(nextRefillDate: refillDate));
    }
  }

  Future<void> _saveMedications(List<Medication> medications) async {
    final jsonList = medications.map((med) => med.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_medicationsKey, jsonString);
  }

  Future<void> clearAllMedications() async {
    await _prefs.remove(_medicationsKey);
  }
}