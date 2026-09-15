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
  });

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
      };

  factory PrescriptionDocument.fromJson(Map<String, dynamic> json) {
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
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ?? DateTime.now(),
      plainLanguageSummary: json['plainLanguageSummary'] as String? ?? '',
      detailedExplanation: json['detailedExplanation'] as String? ?? '',
      keyFindings: (json['keyFindings'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      doctorQuestions: (json['doctorQuestions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      isImage: json['isImage'] as bool? ?? true,
    );
  }
}
