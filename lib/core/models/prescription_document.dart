enum PrescriptionSource { camera, gallery, files }

enum PrescriptionDocType { prescription, labReport, other }

class PrescriptionDocument {
  final String id;
  final String fileName;
  final String localPath;
  final PrescriptionSource source;
  final PrescriptionDocType docType;
  final DateTime uploadedAt;
  final String plainLanguageSummary;
  final String detailedExplanation;
  final List<String> keyFindings;
  final List<String> doctorQuestions;
  final bool isImage;
  /// 0–100 from Edge Function OCR; 0 means unknown / not yet processed.
  final int ocrConfidence;
  final String overallUrgency;
  final String urgencyBanner;
  final String recommendedSpecialist;
  final List<String> carePlan;
  final List<String> redFlags;
  final List<String> medicineEducation;
  /// Raw structured tests from interpret-lab (maps to Biomarker cards).
  final List<Map<String, dynamic>> structuredTests;
  final String analysisStatus;
  /// Local path of the plain-language PDF, when one has been written.
  final String pdfPath;

  const PrescriptionDocument({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.source,
    required this.docType,
    required this.uploadedAt,
    required this.plainLanguageSummary,
    required this.detailedExplanation,
    required this.keyFindings,
    required this.doctorQuestions,
    this.isImage = true,
    this.ocrConfidence = 0,
    this.overallUrgency = 'routine',
    this.urgencyBanner = '',
    this.recommendedSpecialist = 'General Physician',
    this.carePlan = const [],
    this.redFlags = const [],
    this.medicineEducation = const [],
    this.structuredTests = const [],
    this.analysisStatus = 'pending',
    this.pdfPath = '',
  });

  PrescriptionDocument copyWith({
    String? id,
    String? fileName,
    String? localPath,
    PrescriptionSource? source,
    PrescriptionDocType? docType,
    DateTime? uploadedAt,
    String? plainLanguageSummary,
    String? detailedExplanation,
    List<String>? keyFindings,
    List<String>? doctorQuestions,
    bool? isImage,
    int? ocrConfidence,
    String? overallUrgency,
    String? urgencyBanner,
    String? recommendedSpecialist,
    List<String>? carePlan,
    List<String>? redFlags,
    List<String>? medicineEducation,
    List<Map<String, dynamic>>? structuredTests,
    String? analysisStatus,
    String? pdfPath,
  }) {
    return PrescriptionDocument(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      source: source ?? this.source,
      docType: docType ?? this.docType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      plainLanguageSummary: plainLanguageSummary ?? this.plainLanguageSummary,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      keyFindings: keyFindings ?? this.keyFindings,
      doctorQuestions: doctorQuestions ?? this.doctorQuestions,
      isImage: isImage ?? this.isImage,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      overallUrgency: overallUrgency ?? this.overallUrgency,
      urgencyBanner: urgencyBanner ?? this.urgencyBanner,
      recommendedSpecialist: recommendedSpecialist ?? this.recommendedSpecialist,
      carePlan: carePlan ?? this.carePlan,
      redFlags: redFlags ?? this.redFlags,
      medicineEducation: medicineEducation ?? this.medicineEducation,
      structuredTests: structuredTests ?? this.structuredTests,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'localPath': localPath,
        'source': source.name,
        'docType': docType.name,
        'uploadedAt': uploadedAt.toIso8601String(),
        'plainLanguageSummary': plainLanguageSummary,
        'detailedExplanation': detailedExplanation,
        'keyFindings': keyFindings,
        'doctorQuestions': doctorQuestions,
        'isImage': isImage,
        'ocrConfidence': ocrConfidence,
        'overallUrgency': overallUrgency,
        'urgencyBanner': urgencyBanner,
        'recommendedSpecialist': recommendedSpecialist,
        'carePlan': carePlan,
        'redFlags': redFlags,
        'medicineEducation': medicineEducation,
        'structuredTests': structuredTests,
        'analysisStatus': analysisStatus,
        'pdfPath': pdfPath,
      };

  factory PrescriptionDocument.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    List<Map<String, dynamic>> mapList(dynamic v) {
      if (v is! List) return [];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return PrescriptionDocument(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      localPath: json['localPath'] as String,
      source: PrescriptionSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => PrescriptionSource.files,
      ),
      docType: PrescriptionDocType.values.firstWhere(
        (e) => e.name == json['docType'],
        orElse: () => PrescriptionDocType.other,
      ),
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
          DateTime.now(),
      plainLanguageSummary: json['plainLanguageSummary'] as String? ?? '',
      detailedExplanation: json['detailedExplanation'] as String? ?? '',
      keyFindings: strList(json['keyFindings']),
      doctorQuestions: strList(json['doctorQuestions']),
      isImage: json['isImage'] as bool? ?? true,
      ocrConfidence: (json['ocrConfidence'] as num?)?.toInt() ?? 0,
      overallUrgency: json['overallUrgency'] as String? ?? 'routine',
      urgencyBanner: json['urgencyBanner'] as String? ?? '',
      recommendedSpecialist:
          json['recommendedSpecialist'] as String? ?? 'General Physician',
      carePlan: strList(json['carePlan']),
      redFlags: strList(json['redFlags']),
      medicineEducation: strList(json['medicineEducation']),
      structuredTests: mapList(json['structuredTests']),
      analysisStatus: json['analysisStatus'] as String? ?? 'pending',
      pdfPath: json['pdfPath'] as String? ?? '',
    );
  }
}
