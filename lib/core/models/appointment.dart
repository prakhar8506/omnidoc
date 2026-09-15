import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String doctorName;
  final String doctorTitle;
  final String specialty;
  final String avatarUrl;
  final DateTime dateTime;
  final String clinicName;
  final String roomOrType;
  final bool isVideoConsult;
  final String status;
  final String preparationNote;
  final Color themeColor;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.doctorTitle,
    required this.specialty,
    required this.avatarUrl,
    required this.dateTime,
    required this.clinicName,
    required this.roomOrType,
    this.isVideoConsult = false,
    required this.status,
    required this.preparationNote,
    this.themeColor = const Color(0xFF2E5BFF),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'doctorTitle': doctorTitle,
        'specialty': specialty,
        'avatarUrl': avatarUrl,
        'dateTime': dateTime.toIso8601String(),
        'clinicName': clinicName,
        'roomOrType': roomOrType,
        'isVideoConsult': isVideoConsult,
        'status': status,
        'preparationNote': preparationNote,
        'themeColor': themeColor.toARGB32(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      doctorTitle: json['doctorTitle'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
      clinicName: json['clinicName'] as String? ?? '',
      roomOrType: json['roomOrType'] as String? ?? '',
      isVideoConsult: json['isVideoConsult'] as bool? ?? false,
      status: json['status'] as String? ?? 'Confirmed',
      preparationNote: json['preparationNote'] as String? ?? '',
      themeColor: Color(json['themeColor'] as int? ?? 0xFF2E5BFF),
    );
  }
}
