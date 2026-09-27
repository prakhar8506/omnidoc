enum BiomarkerStatus { normal, elevated, low, optimal, severe, mild, moderate, critical }

class DiscussedMedicine {
  final String name;
  final String whyDiscussed;
  final String note;

  const DiscussedMedicine({
    required this.name,
    required this.whyDiscussed,
    required this.note,
  });

  factory DiscussedMedicine.fromJson(Map<String, dynamic> json) {
    return DiscussedMedicine(
      name: (json['name'] ?? '').toString(),
      whyDiscussed: (json['why_discussed'] ?? json['whyDiscussed'] ?? '').toString(),
      note: (json['note'] ??
              'Discuss with your doctor before taking — not a prescription from Cura.')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'why_discussed': whyDiscussed,
        'note': note,
      };
}

class Biomarker {
  final String code;
  final String name;
  final String fullCategory;
  final String value;
  final String unit;
  final String referenceRange;
  final BiomarkerStatus status;
  final String plainSummary;
  final String clinicalContext;
  final String trendText;
  final bool isAttentionFlagged;
  final List<double> historyTrend;
  final String severity;
  final String whatItMeans;
  final List<String> possibleCauses;
  final List<String> lifestyleMeasures;
  final List<String> precautions;
  final String consultUrgency;
  final String specialist;
  final List<DiscussedMedicine> commonlyDiscussedMedicines;

  const Biomarker({
    required this.code,
    required this.name,
    required this.fullCategory,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
    required this.plainSummary,
    required this.clinicalContext,
    required this.trendText,
    this.isAttentionFlagged = false,
    required this.historyTrend,
    this.severity = 'normal',
    this.whatItMeans = '',
    this.possibleCauses = const [],
    this.lifestyleMeasures = const [],
    this.precautions = const [],
    this.consultUrgency = 'routine',
    this.specialist = 'General Physician',
    this.commonlyDiscussedMedicines = const [],
  });
}

class DiagnosticReport {
  final String id;
  final String title;
  final String laboratory;
  final String verifiedDoctor;
  final DateTime date;
  final int totalTested;
  final int outOfRangeCount;
  final int confidencePercentage;
  final String overallSynthesis;
  final String detailedExplanation;
  final String overallUrgency;
  final String urgencyBanner;
  final String recommendedSpecialist;
  final List<String> carePlan;
  final List<String> redFlags;
  final List<String> medicineEducation;
  final List<Biomarker> biomarkers;
  final List<String> recommendedDoctorQuestions;

  const DiagnosticReport({
    required this.id,
    required this.title,
    required this.laboratory,
    required this.verifiedDoctor,
    required this.date,
    required this.totalTested,
    required this.outOfRangeCount,
    required this.confidencePercentage,
    required this.overallSynthesis,
    this.detailedExplanation = '',
    this.overallUrgency = 'routine',
    this.urgencyBanner = '',
    this.recommendedSpecialist = 'General Physician',
    this.carePlan = const [],
    this.redFlags = const [],
    this.medicineEducation = const [],
    required this.biomarkers,
    required this.recommendedDoctorQuestions,
  });
}
