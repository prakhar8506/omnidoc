import 'package:flutter/material.dart';

enum TriageUrgency { low, moderate, urgent, emergency }

class SelfCareGuidance {
  final IconData icon;
  final String title;
  final String description;

  const SelfCareGuidance({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class TriageAssessment {
  final String id;
  final String userQuery;
  final DateTime timestamp;
  final TriageUrgency urgency;
  final String urgencyBadge;
  final String timeframeWindow;
  final String clinicalRationale;
  final List<SelfCareGuidance> selfCareItems;
  final List<String> redFlagAlerts;
  final String recommendedSpecialty;
  final String audioNarrationTranscript;

  const TriageAssessment({
    required this.id,
    required this.userQuery,
    required this.timestamp,
    required this.urgency,
    required this.urgencyBadge,
    required this.timeframeWindow,
    required this.clinicalRationale,
    required this.selfCareItems,
    required this.redFlagAlerts,
    required this.recommendedSpecialty,
    required this.audioNarrationTranscript,
  });
}
