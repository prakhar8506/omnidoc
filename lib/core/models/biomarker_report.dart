enum BiomarkerStatus { normal, elevated, low, optimal }

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
    required this.biomarkers,
    required this.recommendedDoctorQuestions,
  });
}
