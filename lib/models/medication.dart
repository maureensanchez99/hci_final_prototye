class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final int quantity;
  final DateTime startDate;
  final DateTime? nextRefillDate;
  final String? notes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.quantity,
    required this.startDate,
    this.nextRefillDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'quantity': quantity,
      'startDate': startDate.toIso8601String(),
      'nextRefillDate': nextRefillDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      quantity: json['quantity'],
      startDate: DateTime.parse(json['startDate']),
      nextRefillDate: json['nextRefillDate'] != null
          ? DateTime.parse(json['nextRefillDate'])
          : null,
      notes: json['notes'],
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    int? quantity,
    DateTime? startDate,
    DateTime? nextRefillDate,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      nextRefillDate: nextRefillDate ?? this.nextRefillDate,
      notes: notes ?? this.notes,
    );
  }
}
