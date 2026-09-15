class VitalMetric {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final String status;
  final double trendPercentage;
  final List<double> historyPoints;

  const VitalMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.status,
    required this.trendPercentage,
    required this.historyPoints,
  });
}

class MedicationItem {
  final String id;
  final String name;
  final String dosage;
  final String scheduleTime;
  final String instruction;
  bool isTaken;

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduleTime,
    required this.instruction,
    this.isTaken = false,
  });
}
