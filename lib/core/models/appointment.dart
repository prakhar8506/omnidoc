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
}
