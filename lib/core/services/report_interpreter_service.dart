import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
    final dir = Directory(p.join(root.path, 'cura', userId, 'uploads'));
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

    return PrescriptionDocument(
      id: _uuid.v4(),
      fileName: fileName,
      localPath: localPath,
      source: source,
      docType: docType,
      uploadedAt: DateTime.now(),
      isImage: isImage,
      plainLanguageSummary:
          'Document saved. Analysis runs when you are online and signed in.',
      detailedExplanation:
          'Your file was stored securely. Automated OCR and clinical interpretation '
          'run through Cura’s interpret-lab service. Until processing completes, '
          'review the original document with your clinician. Cura does not invent lab values.',
      keyFindings: const [
        'Awaiting OCR processing',
      ],
      doctorQuestions: const [
        'Can you help me interpret this document?',
        'Is any follow-up needed based on this file?',
      ],
    );
  }

  /// Upload to Supabase Storage and invoke interpret-lab with Gemini OCR.
  static Future<PrescriptionDocument> interpretUploadAsync({
    required String fileName,
    required String localPath,
    required PrescriptionSource source,
    required bool isImage,
    String? documentId,
  }) async {
    final pending = interpretUpload(
      fileName: fileName,
      localPath: localPath,
      source: source,
      isImage: isImage,
    );
    final docId = documentId ?? pending.id;

    final base = AppEnv.functionsBaseUrl;
    if (base.isEmpty || !AppEnv.isSupabaseConfigured) {
      return pending.copyWith(id: docId);
    }

    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;
      if (session == null || user == null) {
        return pending.copyWith(id: docId);
      }

      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final storagePath = '${user.id}/$docId/$safeName';
      final mime = _guessMime(fileName, isImage);

      if (kIsWeb || localPath.isEmpty) {
        return pending.copyWith(id: docId);
      }

      final bytes = await File(localPath).readAsBytes();
      final useInline = bytes.length <= 4 * 1024 * 1024;

      await client.storage.from('lab-uploads').uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: mime, upsert: true),
          );

      try {
        await client.from('lab_documents').upsert({
          'id': docId,
          'user_id': user.id,
          'storage_path': storagePath,
          'file_name': fileName,
          'status': 'uploaded',
        });
      } catch (e) {
        debugPrint('[ReportInterpreterService] lab_documents upsert: $e');
      }

      final body = <String, dynamic>{
        'document_id': docId,
        'storage_path': storagePath,
        'file_name': fileName,
        'mime_type': mime,
      };
      if (useInline) {
        body['image_base64'] = base64Encode(bytes);
      }

      final response = await http
          .post(
            Uri.parse('$base/interpret-lab'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
              'apikey': AppEnv.supabaseAnonKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return _documentFromRemote(pending.copyWith(id: docId), decoded);
        }
      } else {
        debugPrint(
          '[ReportInterpreterService] interpret-lab HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[ReportInterpreterService] interpret-lab invoke failed: $e');
    }

    return pending.copyWith(id: docId);
  }

  static PrescriptionDocument _documentFromRemote(
    PrescriptionDocument pending,
    Map decoded,
  ) {
    final summary = (decoded['plainLanguageSummary'] ??
            decoded['ai_summary'] ??
            decoded['summary'] ??
            decoded['message'])
        ?.toString();
    final detailed = (decoded['detailedExplanation'] ??
            decoded['ai_summary'] ??
            decoded['explanation'])
        ?.toString();
    final findings = decoded['keyFindings'];
    final questions = decoded['doctorQuestions'] ?? decoded['doctor_questions'];

    return PrescriptionDocument(
      id: pending.id,
      fileName: pending.fileName,
      localPath: pending.localPath,
      source: pending.source,
      docType: pending.docType,
      uploadedAt: pending.uploadedAt,
      isImage: pending.isImage,
      plainLanguageSummary: (summary != null && summary.trim().isNotEmpty)
          ? summary.trim()
          : pending.plainLanguageSummary,
      detailedExplanation: (detailed != null && detailed.trim().isNotEmpty)
          ? detailed.trim()
          : pending.detailedExplanation,
      keyFindings: findings is List
          ? findings.map((e) => e.toString()).toList()
          : pending.keyFindings,
      doctorQuestions: questions is List
          ? questions.map((e) => e.toString()).toList()
          : pending.doctorQuestions,
    );
  }

  static String _guessMime(String fileName, bool isImage) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (isImage) return 'image/jpeg';
    return 'application/octet-stream';
  }

  static DiagnosticReport labReportFromPrescription(PrescriptionDocument doc) {
    final findings = doc.keyFindings;
    return DiagnosticReport(
      id: 'rep-${doc.id}',
      title: doc.docType == PrescriptionDocType.prescription
          ? 'Prescription Review'
          : 'Imported Health Document',
      laboratory: doc.fileName,
      verifiedDoctor: 'Pending clinician review',
      date: doc.uploadedAt,
      totalTested: findings.length,
      outOfRangeCount: findings.where((f) => f.contains('(high)') || f.contains('(low)')).length,
      confidencePercentage: findings.any((f) => f != 'Awaiting OCR processing') ? 70 : 0,
      overallSynthesis: doc.plainLanguageSummary,
      biomarkers: findings.isEmpty
          ? const [
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
                plainSummary: 'Document saved. Waiting for OCR.',
                clinicalContext: 'Patient-uploaded document — no invented values.',
                historyTrend: [1, 1, 1, 1, 1],
              ),
            ]
          : [
              for (var i = 0; i < findings.length; i++)
                Biomarker(
                  code: 'F$i',
                  name: findings[i].split(':').first.trim(),
                  fullCategory: 'Imported Record',
                  value: findings[i].contains(':')
                      ? findings[i].split(':').skip(1).join(':').trim()
                      : findings[i],
                  unit: '',
                  referenceRange: 'See original report',
                  status: findings[i].contains('(high)')
                      ? BiomarkerStatus.elevated
                      : findings[i].contains('(low)')
                          ? BiomarkerStatus.low
                          : BiomarkerStatus.optimal,
                  isAttentionFlagged:
                      findings[i].contains('(high)') || findings[i].contains('(low)'),
                  trendText: 'From uploaded document',
                  plainSummary: findings[i],
                  clinicalContext: doc.detailedExplanation,
                  historyTrend: const [1, 1, 1, 1, 1],
                ),
            ],
      recommendedDoctorQuestions: doc.doctorQuestions,
    );
  }
}
