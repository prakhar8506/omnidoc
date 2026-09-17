import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../env/app_env.dart';
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

    // Honest pending summary — no invented biomarker values
    return PrescriptionDocument(
      id: _uuid.v4(),
      fileName: fileName,
      localPath: localPath,
      source: source,
      docType: docType,
      uploadedAt: DateTime.now(),
      isImage: isImage,
      plainLanguageSummary:
          'Document saved. Analysis runs when lab Edge Function is configured.',
      detailedExplanation:
          'Your file was stored securely on this device. '
          'Automated OCR and clinical interpretation require the interpret-lab Edge Function. '
          'Until that is configured, review the original document with your clinician. '
          'This app does not invent lab values from filenames.',
      keyFindings: const [
        'Awaiting OCR processing',
      ],
      doctorQuestions: const [
        'Can you help me interpret this document?',
        'Is any follow-up needed based on this file?',
      ],
    );
  }

  /// Optionally invoke the interpret-lab Edge Function when configured.
  static Future<PrescriptionDocument> interpretUploadAsync({
    required String fileName,
    required String localPath,
    required PrescriptionSource source,
    required bool isImage,
  }) async {
    final pending = interpretUpload(
      fileName: fileName,
      localPath: localPath,
      source: source,
      isImage: isImage,
    );

    final base = AppEnv.functionsBaseUrl;
    if (base.isEmpty) return pending;

    try {
      String? sessionToken;
      try {
        sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        sessionToken = null;
      }
      final bearer = (sessionToken != null && sessionToken.isNotEmpty)
          ? sessionToken
          : AppEnv.supabaseAnonKey;

      final response = await http
          .post(
            Uri.parse('$base/interpret-lab'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $bearer',
              'apikey': AppEnv.supabaseAnonKey,
            },
            body: jsonEncode({
              'fileName': fileName,
              'localPath': localPath,
              'isImage': isImage,
              'docType': pending.docType.name,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final summary = (decoded['plainLanguageSummary'] ??
                  decoded['summary'] ??
                  decoded['message'])
              ?.toString();
          final detailed = (decoded['detailedExplanation'] ?? decoded['explanation'])
              ?.toString();
          final findings = decoded['keyFindings'];
          final questions = decoded['doctorQuestions'];

          if (summary != null && summary.trim().isNotEmpty) {
            return PrescriptionDocument(
              id: pending.id,
              fileName: pending.fileName,
              localPath: pending.localPath,
              source: pending.source,
              docType: pending.docType,
              uploadedAt: pending.uploadedAt,
              isImage: pending.isImage,
              plainLanguageSummary: summary.trim(),
              detailedExplanation: detailed?.trim().isNotEmpty == true
                  ? detailed!.trim()
                  : pending.detailedExplanation,
              keyFindings: findings is List
                  ? findings.map((e) => e.toString()).toList()
                  : pending.keyFindings,
              doctorQuestions: questions is List
                  ? questions.map((e) => e.toString()).toList()
                  : pending.doctorQuestions,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ReportInterpreterService] interpret-lab invoke failed: $e');
    }

    return pending;
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
      confidencePercentage: 0,
      overallSynthesis: doc.plainLanguageSummary,
      biomarkers: const [
        Biomarker(
          code: 'NOTE',
          name: 'Document Summary',
          fullCategory: 'Imported Record',
          value: 'Pending',
          unit: '',
          referenceRange: 'N/A',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'Awaiting analysis',
          plainSummary:
              'Document saved. Analysis runs when lab Edge Function is configured.',
          clinicalContext: 'Patient-uploaded document — no invented values.',
          historyTrend: [1, 1, 1, 1, 1],
        ),
      ],
      recommendedDoctorQuestions: doc.doctorQuestions,
    );
  }
}
