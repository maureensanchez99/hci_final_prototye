import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String medicationId;
  final String medicationName;
  final int daysBeforeRefill;
  final DateTime? lastNotificationDate;
  final bool isActive;
  final DateTime createdDate;
  final TimeOfDay notificationTime;

  Reminder({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.daysBeforeRefill,
    this.lastNotificationDate,
    this.isActive = true,
    required this.createdDate,
    TimeOfDay? notificationTime,
  }) : notificationTime = notificationTime ?? const TimeOfDay(hour: 9, minute: 0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'daysBeforeRefill': daysBeforeRefill,
      'lastNotificationDate': lastNotificationDate?.toIso8601String(),
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
      'notificationHour': notificationTime.hour,
      'notificationMinute': notificationTime.minute,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      medicationId: json['medicationId'],
      medicationName: json['medicationName'],
      daysBeforeRefill: json['daysBeforeRefill'],
      lastNotificationDate: json['lastNotificationDate'] != null
          ? DateTime.parse(json['lastNotificationDate'])
          : null,
      isActive: json['isActive'] ?? true,
      createdDate: DateTime.parse(json['createdDate']),
      notificationTime: TimeOfDay(
        hour: json['notificationHour'] ?? 9,
        minute: json['notificationMinute'] ?? 0,
      ),
    );
  }

  Reminder copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    int? daysBeforeRefill,
    DateTime? lastNotificationDate,
    bool? isActive,
    DateTime? createdDate,
    TimeOfDay? notificationTime,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      daysBeforeRefill: daysBeforeRefill ?? this.daysBeforeRefill,
      lastNotificationDate: lastNotificationDate ?? this.lastNotificationDate,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}
