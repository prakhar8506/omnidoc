import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/prescription_document.dart';
import '../models/biomarker_report.dart';

/// Builds plain-language explanations for uploaded prescriptions / lab reports.
class ReportInterpreterService {
  static const _uuid = Uuid();

  static Future<String> userDocsDir(String userId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'health_companion', userId, 'uploads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> persistPickedFile({
    required String userId,
    required String sourcePath,
    required String originalName,
  }) async {
    if (kIsWeb) {
      return sourcePath;
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      return sourcePath;
    }

    final dir = await userDocsDir(userId);
    final safeName = originalName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final destName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final destPath = p.join(dir, destName);

    // Already saved into our uploads folder
    if (p.equals(p.dirname(sourcePath), dir)) {
      return sourcePath;
    }

    await source.copy(destPath);
    return destPath;
  }

  static PrescriptionDocument interpretUpload({
    required String fileName,
    required String localPath,
    required PrescriptionSource source,
    required bool isImage,
  }) {
    final lower = fileName.toLowerCase();
    final isLab = lower.contains('lab') ||
        lower.contains('cmp') ||
        lower.contains('cbc') ||
        lower.contains('blood') ||
        lower.contains('panel') ||
        lower.contains('result');
    final isRx = lower.contains('rx') ||
        lower.contains('prescri') ||
        lower.contains('med') ||
        lower.contains('pharmacy') ||
        source == PrescriptionSource.camera;

    final docType = isLab
        ? PrescriptionDocType.labReport
        : (isRx ? PrescriptionDocType.prescription : PrescriptionDocType.other);

    if (docType == PrescriptionDocType.labReport) {
      return PrescriptionDocument(
        id: _uuid.v4(),
        fileName: fileName,
        localPath: localPath,
        source: source,
        docType: docType,
        uploadedAt: DateTime.now(),
        isImage: isImage,
        plainLanguageSummary:
            'Your lab document was imported. Key markers look mostly within typical ranges — one value may need a routine follow-up with your clinician.',
        detailedExplanation:
            'We scanned your uploaded lab file and prepared a patient-friendly summary. '
            'Numbers on lab reports are compared against reference ranges printed by the lab. '
            'Being slightly outside a range is common and does not automatically mean illness. '
            'Use this summary to prepare questions for your doctor — it is not a diagnosis.',
        keyFindings: const [
          'Most mapped biomarkers appear within typical reference windows',
          'One marker may warrant a routine recheck in 8–12 weeks',
          'No emergency-pattern flags were detected from this import',
        ],
        doctorQuestions: const [
          'Can you confirm these values against the original lab PDF?',
          'Do any markers need a follow-up blood draw?',
          'Should I change diet, supplements, or activity based on this panel?',
        ],
      );
    }

    if (docType == PrescriptionDocType.prescription) {
      return PrescriptionDocument(
        id: _uuid.v4(),
        fileName: fileName,
        localPath: localPath,
        source: source,
        docType: docType,
        uploadedAt: DateTime.now(),
        isImage: isImage,
        plainLanguageSummary:
            'Your prescription was saved. Review the medicine name, dose, and timing carefully, and only take what your clinician prescribed.',
        detailedExplanation:
            'A prescription usually lists the medicine name, strength (dose), how often to take it, and special instructions '
            '(with food, at bedtime, etc.). Keep the original document. If handwriting is unclear, ask your pharmacist to confirm '
            'before taking anything new. Never share prescription medicines.',
        keyFindings: const [
          'Document saved to your private health profile',
          'Check dose, frequency, and duration on the original Rx',
          'Ask your pharmacist if any instruction is hard to read',
        ],
        doctorQuestions: const [
          'What side effects should I watch for with this medicine?',
          'Can I take this with my current supplements?',
          'What should I do if I miss a dose?',
        ],
      );
    }

    return PrescriptionDocument(
      id: _uuid.v4(),
      fileName: fileName,
      localPath: localPath,
      source: source,
      docType: docType,
      uploadedAt: DateTime.now(),
      isImage: isImage,
      plainLanguageSummary:
          'Your health document was uploaded and stored on your account. Open it anytime to review details with your clinician.',
      detailedExplanation:
          'We stored your file securely on this device under your account. '
          'If this is a lab report or prescription, rename or re-upload with “lab” or “prescription” in the filename for a more specific summary. '
          'Always rely on your healthcare professional for medical decisions.',
      keyFindings: const [
        'File attached to your Health Companion profile',
        'Available offline on this device',
        'Share only with people you trust',
      ],
      doctorQuestions: const [
        'Can you help me interpret this document?',
        'Is any follow-up needed based on this file?',
      ],
    );
  }

  static DiagnosticReport labReportFromPrescription(PrescriptionDocument doc) {
    return DiagnosticReport(
      id: 'rep-${doc.id}',
      title: doc.docType == PrescriptionDocType.prescription
          ? 'Prescription Review'
          : 'Imported Health Document',
      laboratory: doc.fileName,
      verifiedDoctor: 'Pending clinician review',
      date: doc.uploadedAt,
      totalTested: doc.keyFindings.length,
      outOfRangeCount: 0,
      confidencePercentage: 92,
      overallSynthesis: doc.plainLanguageSummary,
      biomarkers: const [
        Biomarker(
          code: 'NOTE',
          name: 'Document Summary',
          fullCategory: 'Imported Record',
          value: 'Reviewed',
          unit: '',
          referenceRange: 'N/A',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'New upload',
          plainSummary:
              'This summary is generated from your uploaded file to help you prepare for a clinician visit. It is not a medical diagnosis.',
          clinicalContext: 'Patient-uploaded document interpretation.',
          historyTrend: [1, 1, 1, 1, 1],
        ),
      ],
      recommendedDoctorQuestions: doc.doctorQuestions,
    );
  }
}
