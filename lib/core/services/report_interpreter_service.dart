import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../env/app_env.dart';
import '../models/prescription_document.dart';
import '../models/biomarker_report.dart';
import 'lab_report_pdf.dart';

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
    Uint8List? bytes,
  }) async {
    if (kIsWeb) {
      return sourcePath;
    }

    final dir = await userDocsDir(userId);
    final safeName = originalName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final destName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final destPath = p.join(dir, destName);

    if (bytes != null && bytes.isNotEmpty) {
      await File(destPath).writeAsBytes(bytes, flush: true);
      return destPath;
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      return sourcePath;
    }

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
        lower.contains('result') ||
        lower.contains('hb') ||
        lower.contains('report');
    final isRx = lower.contains('rx') ||
        lower.contains('prescri') ||
        lower.contains('med') ||
        lower.contains('pharmacy');

    final docType = isLab
        ? PrescriptionDocType.labReport
        : (isRx || source == PrescriptionSource.camera
            ? PrescriptionDocType.prescription
            : PrescriptionDocType.labReport);

    return PrescriptionDocument(
      id: _uuid.v4(),
      fileName: fileName,
      localPath: localPath,
      source: source,
      docType: docType,
      uploadedAt: DateTime.now(),
      isImage: isImage,
      plainLanguageSummary:
          'Uploading and analyzing your report with AI… please wait a moment.',
      detailedExplanation:
          'Cura is reading your document with secure OCR and building a plain-language '
          'explanation: what each number means, whether it is normal or not, what often '
          'causes changes, lifestyle steps, which doctor to see, and medicines clinicians '
          'commonly discuss (educational only — not a prescription).',
      keyFindings: const [
        'Awaiting OCR processing',
      ],
      doctorQuestions: const [
        'Can you help me interpret this document?',
        'Is any follow-up needed based on this file?',
      ],
      analysisStatus: 'analyzing',
      urgencyBanner: 'Analysis in progress…',
    );
  }

  /// Restores or creates a Supabase session so lab OCR can run even when the
  /// local profile exists but the cloud token expired or was never issued.
  static Future<Session?> _ensureCloudSession(SupabaseClient client) async {
    final current = client.auth.currentSession;
    if (current != null && !current.isExpired) return current;

    try {
      final refreshed = await client.auth.refreshSession();
      if (refreshed.session != null) return refreshed.session;
    } catch (e) {
      debugPrint('[ReportInterpreterService] session refresh: $e');
    }

    return client.auth.currentSession;
  }

  /// Upload to Supabase Storage and invoke interpret-lab with Gemini OCR.
  static Future<PrescriptionDocument> interpretUploadAsync({
    required String fileName,
    required String localPath,
    required PrescriptionSource source,
    required bool isImage,
    String? documentId,
    Uint8List? fileBytes,
    String patientName = 'Patient',
    String userId = 'local',
    void Function(String stage, double progress)? onProgress,
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
      return pending.copyWith(
        id: docId,
        analysisStatus: 'offline',
        plainLanguageSummary:
            'Saved on this device. Sign in with internet to run AI lab analysis.',
        detailedExplanation:
            'Cloud OCR needs Supabase configuration and a signed-in session. '
            'Your file is kept locally until analysis can run.',
      );
    }

    try {
      final client = Supabase.instance.client;
      final session = await _ensureCloudSession(client);
      final user = client.auth.currentUser;
      final accessToken = session?.accessToken ?? AppEnv.supabaseAnonKey;

      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final storagePath = user != null
          ? '${user.id}/$docId/$safeName'
          : 'guest/$docId/$safeName';
      final mime = _guessMime(fileName, isImage);

      Uint8List bytes;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        bytes = fileBytes;
      } else if (!kIsWeb && localPath.isNotEmpty && await File(localPath).exists()) {
        bytes = await File(localPath).readAsBytes();
      } else {
        return pending.copyWith(
          id: docId,
          analysisStatus: 'missing_file',
          plainLanguageSummary:
              'Could not read the file bytes. Try uploading again from camera or gallery.',
        );
      }

      final useInline = bytes.length <= 4 * 1024 * 1024;

      if (user != null && session != null) {
        try {
          await client.storage.from('lab-uploads').uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(contentType: mime, upsert: true),
              );
          await client.from('lab_documents').upsert({
            'id': docId,
            'user_id': user.id,
            'storage_path': storagePath,
            'file_name': fileName,
            'status': 'uploaded',
          });
        } catch (e) {
          debugPrint('[ReportInterpreterService] storage/doc upsert: $e');
        }
      }

      onProgress?.call('Uploading your report securely', 0.18);

      final body = <String, dynamic>{
        'document_id': docId,
        'storage_path': storagePath,
        'file_name': fileName,
        'mime_type': mime,
      };
      if (useInline || user == null || bytes.length <= 8 * 1024 * 1024) {
        body['image_base64'] = base64Encode(bytes);
      }

      onProgress?.call('Analysing your report', 0.32);
      final pulse = Timer.periodic(const Duration(seconds: 4), (timer) {
        const stages = <(String, double)>[
          ('Reading each test and number', 0.42),
          ('Calculating what is normal, mild, or severe', 0.55),
          ('Contemplating causes, precautions, and which doctor to see', 0.68),
          ('Writing the explanation in simple words', 0.78),
        ];
        final step = stages[timer.tick % stages.length];
        onProgress?.call(step.$1, step.$2);
      });

      http.Response response;
      try {
        response = await http
          .post(
            Uri.parse('$base/interpret-lab'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'apikey': AppEnv.supabaseAnonKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));
      } finally {
        pulse.cancel();
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        onProgress?.call('Checking the explanation', 0.86);
        final decoded = jsonDecode(response.body);
        final remoteError = decoded is Map ? (decoded['error']?.toString() ?? '') : '';
        if (decoded is Map && remoteError.isEmpty) {
          var doc = _documentFromRemote(pending.copyWith(id: docId), decoded);
          if (doc.analysisStatus == 'ready' || doc.structuredTests.isNotEmpty) {
            onProgress?.call('Building your plain-language PDF', 0.93);
            try {
              final report = labReportFromPrescription(doc);
              final pdfPath = await LabReportPdf.write(
                userId: userId,
                report: report,
                patientName: patientName,
              );
              doc = doc.copyWith(pdfPath: pdfPath, analysisStatus: 'ready');
            } catch (e) {
              debugPrint('[ReportInterpreterService] pdf: $e');
            }
            onProgress?.call('Your explanation is ready', 1);
            return doc;
          }
        }
      }

      debugPrint(
        '[ReportInterpreterService] interpret-lab HTTP ${response.statusCode}: ${response.body}',
      );
      final fallback = await _explainFromDeviceText(
        pending: pending.copyWith(id: docId),
        localPath: localPath,
        bytes: bytes,
        isImage: isImage,
        accessToken: accessToken,
        patientName: patientName,
        userId: userId,
        onProgress: onProgress,
      );
      if (fallback != null) return fallback;
      return pending.copyWith(
        id: docId,
        analysisStatus: 'error',
        urgencyBanner: 'Analysis did not finish',
        plainLanguageSummary: _friendlyHttpError(response.statusCode),
        detailedExplanation: _friendlyHttpError(response.statusCode),
      );
    } catch (e) {
      debugPrint('[ReportInterpreterService] interpret-lab invoke failed: $e');
      if (isImage) {
        final fallback = await _explainFromDeviceText(
          pending: pending.copyWith(id: docId),
          localPath: localPath,
          bytes: fileBytes ?? Uint8List(0),
          isImage: isImage,
          accessToken: AppEnv.supabaseAnonKey,
          patientName: patientName,
          userId: userId,
          onProgress: onProgress,
        );
        if (fallback != null) return fallback;
      }
      return pending.copyWith(
        id: docId,
        analysisStatus: 'error',
        plainLanguageSummary:
            'Could not reach the analysis service. Check your connection and try again.',
        detailedExplanation:
            'Your report was saved but could not be explained yet. Reopen this report once you are back online to retry the reading.',
      );
    }
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
            decoded['detailed_explanation'] ??
            decoded['ai_summary'] ??
            decoded['explanation'])
        ?.toString();
    final findings = decoded['keyFindings'];
    final questions = decoded['doctorQuestions'] ?? decoded['doctor_questions'];
    final confidenceRaw = decoded['confidence'] ?? decoded['ocr_confidence'];
    int ocrConfidence = 0;
    if (confidenceRaw is num) {
      ocrConfidence = confidenceRaw <= 1
          ? (confidenceRaw * 100).round().clamp(0, 100)
          : confidenceRaw.round().clamp(0, 100);
    }

    final testsRaw = decoded['tests'];
    final structuredTests = <Map<String, dynamic>>[];
    if (testsRaw is List) {
      for (final t in testsRaw) {
        if (t is Map) structuredTests.add(Map<String, dynamic>.from(t));
      }
    }

    List<String> strList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }

    final status = (decoded['status'] ?? 'interpreted').toString();
    final isReady = structuredTests.isNotEmpty ||
        (summary != null &&
            !summary.toLowerCase().contains('pending') &&
            status == 'interpreted');

    return PrescriptionDocument(
      id: pending.id,
      fileName: pending.fileName,
      localPath: pending.localPath,
      source: pending.source,
      docType: structuredTests.isNotEmpty
          ? PrescriptionDocType.labReport
          : pending.docType,
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
      ocrConfidence: ocrConfidence,
      overallUrgency:
          (decoded['overallUrgency'] ?? decoded['overall_urgency'] ?? 'routine')
              .toString(),
      urgencyBanner:
          (decoded['urgencyBanner'] ?? decoded['urgency_banner'] ?? '').toString(),
      recommendedSpecialist: (decoded['recommendedSpecialist'] ??
              decoded['recommended_specialist'] ??
              'General Physician')
          .toString(),
      carePlan: strList(decoded['carePlan'] ?? decoded['care_plan']),
      redFlags: strList(decoded['redFlags'] ?? decoded['red_flags']),
      medicineEducation:
          strList(decoded['medicineEducation'] ?? decoded['medicine_education']),
      structuredTests: structuredTests,
      analysisStatus: isReady ? 'ready' : status,
    );
  }

  /// When the vision function rejects the session, read the photo on device
  /// and explain that text through the live Health AI chat (anon-capable).
  static Future<PrescriptionDocument?> _explainFromDeviceText({
    required PrescriptionDocument pending,
    required String localPath,
    required Uint8List bytes,
    required bool isImage,
    required String accessToken,
    required String patientName,
    required String userId,
    void Function(String stage, double progress)? onProgress,
  }) async {
    if (kIsWeb || !isImage) return null;
    onProgress?.call('Reading each test and number on your photo', 0.4);

    var imagePath = localPath;
    if (imagePath.isEmpty || !await File(imagePath).exists()) {
      final tmp = File('${Directory.systemTemp.path}/cura-lab-${pending.id}.jpg');
      await tmp.writeAsBytes(bytes, flush: true);
      imagePath = tmp.path;
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String ocrText = '';
    try {
      final recognized = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      ocrText = recognized.text.trim();
    } catch (e) {
      debugPrint('[ReportInterpreterService] on-device OCR: $e');
      return null;
    } finally {
      await recognizer.close();
    }

    if (ocrText.length < 12) return null;
    if (ocrText.length > 12000) {
      ocrText = ocrText.substring(0, 12000);
    }

    onProgress?.call('Calculating what is normal, mild, or severe', 0.58);
    final base = AppEnv.functionsBaseUrl;
    final prompt = '''
The user uploaded their own lab report. The text below was read from THAT photo.
Explain it for someone with no medical training.
Use ONLY numbers and test names that appear in the text. Never invent a result.
Return ONLY JSON (no markdown) with this shape:
{
  "plainLanguageSummary": "3-5 simple sentences",
  "detailedExplanation": "longer walkthrough",
  "overallUrgency": "routine|soon|urgent|emergency",
  "urgencyBanner": "how fast to see a doctor",
  "recommendedSpecialist": "which doctor",
  "confidence": 0.8,
  "carePlan": ["lifestyle steps"],
  "redFlags": ["when to seek care today"],
  "medicineEducation": ["medicines clinicians often discuss, each ending with: Discuss with your doctor before taking — not a prescription from Cura."],
  "doctorQuestions": ["questions for the doctor"],
  "tests": [{
    "name": "",
    "code": "",
    "value": 0,
    "value_text": "",
    "unit": "",
    "ref_text": "",
    "flag": "low|high|normal",
    "severity": "normal|mild|moderate|severe|critical",
    "plain_meaning": "what the test is",
    "what_it_means": "what their number means",
    "possible_causes": [],
    "lifestyle_measures": [],
    "precautions": [],
    "consult_urgency": "routine|soon|urgent|emergency",
    "specialist": "",
    "commonly_discussed_medicines": [{"name":"","why_discussed":"","note":"Discuss with your doctor before taking — not a prescription from Cura."}]
  }]
}

REPORT TEXT:
$ocrText
''';

    final pulse = Timer.periodic(const Duration(seconds: 3), (timer) {
      const stages = <(String, double)>[
        ('Calculating what is normal, mild, or severe', 0.62),
        ('Contemplating causes, precautions, and which doctor to see', 0.74),
        ('Writing the explanation in simple words', 0.84),
      ];
      final step = stages[timer.tick % stages.length];
      onProgress?.call(step.$1, step.$2);
    });

    try {
      var response = await http
          .post(
            Uri.parse('$base/health-ai-chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'apikey': AppEnv.supabaseAnonKey,
            },
            body: jsonEncode({
              'message': prompt,
              'mode': 'lab',
            }),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode >= 500) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        response = await http
            .post(
              Uri.parse('$base/health-ai-chat'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
                'apikey': AppEnv.supabaseAnonKey,
              },
              body: jsonEncode({
                'message': prompt,
                'mode': 'lab',
              }),
            )
            .timeout(const Duration(seconds: 90));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[ReportInterpreterService] chat fallback ${response.statusCode}: ${response.body}');
        return null;
      }
      final decoded = jsonDecode(response.body);
      final reply = decoded is Map
          ? (decoded['reply'] ?? decoded['message'] ?? decoded['text'] ?? '').toString()
          : '';
      if (reply.trim().isEmpty) return null;
      onProgress?.call('Contemplating causes, precautions, and which doctor to see', 0.78);
      final parsed = _labJsonFromReply(reply, ocrText);
      var doc = _documentFromRemote(pending, parsed);
      if (doc.analysisStatus != 'ready' && doc.structuredTests.isEmpty) {
        return null;
      }
      onProgress?.call('Building your plain-language PDF', 0.93);
      try {
        final report = labReportFromPrescription(doc);
        final pdfPath = await LabReportPdf.write(
          userId: userId,
          report: report,
          patientName: patientName,
        );
        doc = doc.copyWith(pdfPath: pdfPath, analysisStatus: 'ready');
      } catch (e) {
        debugPrint('[ReportInterpreterService] fallback pdf: $e');
      }
      onProgress?.call('Your explanation is ready', 1);
      return doc;
    } catch (e) {
      debugPrint('[ReportInterpreterService] chat fallback failed: $e');
      return null;
    } finally {
      pulse.cancel();
    }
  }

  static Map<String, dynamic> _labJsonFromReply(String reply, String ocrText) {
    final jsonText = _extractJson(reply);
    if (jsonText != null) {
      try {
        final parsed = jsonDecode(jsonText);
        if (parsed is Map &&
            (parsed['tests'] is List ||
                (parsed['plainLanguageSummary'] ?? parsed['detailedExplanation']) != null)) {
          return Map<String, dynamic>.from(parsed);
        }
      } catch (_) {}
    }

    final lines = ocrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3 && RegExp(r'\d').hasMatch(l))
        .take(16)
        .toList();
    final firstBreak = reply.indexOf('\n\n');
    final summary = (firstBreak > 40 && firstBreak < 500)
        ? reply.substring(0, firstBreak).trim()
        : (reply.length > 420 ? '${reply.substring(0, 420).trim()}…' : reply.trim());
    return {
      'status': 'interpreted',
      'plainLanguageSummary': summary,
      'detailedExplanation': reply.trim(),
      'overallUrgency': 'soon',
      'urgencyBanner': 'Read this with your doctor before changing any treatment.',
      'recommendedSpecialist': 'General Physician',
      'confidence': 0.55,
      'keyFindings': lines,
      'doctorQuestions': [
        'Which of these results should we follow up first?',
        'Do I need a repeat test or a specialist?',
      ],
    };
  }

  static String? _extractJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  static String _friendlyHttpError(int code) {
    if (code == 401) {
      return 'The lab reader could not start. Stay on this screen — we will retry the explanation automatically.';
    }
    if (code == 413) {
      return 'That photo is too large. Take a closer, smaller picture of the report and upload it again.';
    }
    return 'The explanation did not finish (code $code). Your file is saved. Try the upload once more.';
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

  static BiomarkerStatus _statusFromTest(Map<String, dynamic> t) {
    final severity = (t['severity'] ?? '').toString().toLowerCase();
    final flag = (t['flag'] ?? '').toString().toLowerCase();
    if (severity == 'critical') return BiomarkerStatus.critical;
    if (severity == 'severe') return BiomarkerStatus.severe;
    if (severity == 'moderate') return BiomarkerStatus.moderate;
    if (severity == 'mild') return BiomarkerStatus.mild;
    if (flag == 'high' || flag == 'elevated') return BiomarkerStatus.elevated;
    if (flag == 'low') return BiomarkerStatus.low;
    if (flag == 'normal' || severity == 'normal') return BiomarkerStatus.normal;
    if (flag == 'abnormal') return BiomarkerStatus.elevated;
    return BiomarkerStatus.optimal;
  }

  static String _statusLabel(BiomarkerStatus s) {
    switch (s) {
      case BiomarkerStatus.critical:
        return 'Critical';
      case BiomarkerStatus.severe:
        return 'Severe';
      case BiomarkerStatus.moderate:
        return 'Moderate';
      case BiomarkerStatus.mild:
        return 'Mild';
      case BiomarkerStatus.elevated:
        return 'Above Range';
      case BiomarkerStatus.low:
        return 'Below Range';
      case BiomarkerStatus.normal:
      case BiomarkerStatus.optimal:
        return 'Normal';
    }
  }

  static Biomarker _biomarkerFromStructured(Map<String, dynamic> t, int index) {
    final name = (t['name'] ?? 'Marker ${index + 1}').toString();
    final code = (t['code'] ?? '').toString().trim().isNotEmpty
        ? t['code'].toString()
        : name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final unit = (t['unit'] ?? '').toString();
    final valueText = (t['value_text'] ?? t['valueText'])?.toString();
    final valueNum = t['value'];
    final value = (valueText != null && valueText.isNotEmpty)
        ? valueText
        : (valueNum == null ? '—' : valueNum.toString());
    final refText = (t['ref_text'] ?? t['refText'])?.toString();
    final refLow = t['ref_low'] ?? t['refLow'];
    final refHigh = t['ref_high'] ?? t['refHigh'];
    String referenceRange;
    if (refText != null && refText.trim().isNotEmpty) {
      referenceRange = refText;
    } else if (refLow != null && refHigh != null) {
      referenceRange = '$refLow–$refHigh${unit.isNotEmpty ? ' $unit' : ''}';
    } else {
      referenceRange = 'See original report';
    }

    final status = _statusFromTest(t);
    final flagged = status == BiomarkerStatus.elevated ||
        status == BiomarkerStatus.low ||
        status == BiomarkerStatus.mild ||
        status == BiomarkerStatus.moderate ||
        status == BiomarkerStatus.severe ||
        status == BiomarkerStatus.critical;

    final medsRaw = t['commonly_discussed_medicines'] ?? t['commonlyDiscussedMedicines'];
    final meds = <DiscussedMedicine>[];
    if (medsRaw is List) {
      for (final m in medsRaw) {
        if (m is Map) {
          meds.add(DiscussedMedicine.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    List<String> strList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }

    return Biomarker(
      code: code,
      name: name,
      fullCategory: (t['specialist'] ?? 'Lab Marker').toString(),
      value: value,
      unit: unit,
      referenceRange: referenceRange,
      status: status,
      isAttentionFlagged: flagged,
      trendText: _statusLabel(status),
      plainSummary: (t['plain_meaning'] ?? t['plainMeaning'] ?? name).toString(),
      clinicalContext: (t['what_it_means'] ?? t['whatItMeans'] ?? '').toString(),
      historyTrend: const [1, 1, 1, 1, 1],
      severity: (t['severity'] ?? 'normal').toString(),
      whatItMeans: (t['what_it_means'] ?? t['whatItMeans'] ?? '').toString(),
      possibleCauses: strList(t['possible_causes'] ?? t['possibleCauses']),
      lifestyleMeasures: strList(t['lifestyle_measures'] ?? t['lifestyleMeasures']),
      precautions: strList(t['precautions']),
      consultUrgency: (t['consult_urgency'] ?? t['consultUrgency'] ?? 'routine')
          .toString(),
      specialist: (t['specialist'] ?? 'General Physician').toString(),
      commonlyDiscussedMedicines: meds,
    );
  }

  static DiagnosticReport labReportFromPrescription(PrescriptionDocument doc) {
    final findings = doc.keyFindings;
    final awaiting = findings.any((f) => f.toLowerCase().contains('awaiting'));

    List<Biomarker> biomarkers;
    if (doc.structuredTests.isNotEmpty) {
      biomarkers = [
        for (var i = 0; i < doc.structuredTests.length; i++)
          _biomarkerFromStructured(doc.structuredTests[i], i),
      ];
    } else if (awaiting || findings.isEmpty) {
      biomarkers = [
        Biomarker(
          code: 'OCR',
          name: 'OCR & AI analysis in progress',
          fullCategory: 'Imported Record',
          value: 'Pending',
          unit: '',
          referenceRange: 'N/A',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'Awaiting analysis',
          plainSummary: doc.plainLanguageSummary,
          clinicalContext: doc.detailedExplanation,
          historyTrend: const [1, 1, 1, 1, 1],
        ),
      ];
    } else {
      biomarkers = [
        for (var i = 0; i < findings.length; i++)
          Biomarker(
            code: findings[i].contains(':')
                ? findings[i].split(':').first.trim().split(' ').first
                : 'F$i',
            name: findings[i].contains(':')
                ? findings[i].split(':').first.trim()
                : findings[i],
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
                    : BiomarkerStatus.normal,
            isAttentionFlagged: findings[i].contains('(high)') ||
                findings[i].contains('(low)') ||
                findings[i].contains('[severe]') ||
                findings[i].contains('[critical]'),
            trendText: 'From uploaded document',
            plainSummary: findings[i],
            clinicalContext: doc.detailedExplanation,
            historyTrend: const [1, 1, 1, 1, 1],
          ),
      ];
    }

    final outOfRange = biomarkers.where((b) => b.isAttentionFlagged).length;

    return DiagnosticReport(
      id: 'rep-${doc.id}',
      title: doc.docType == PrescriptionDocType.prescription
          ? 'Prescription Review'
          : 'Lab Report Analysis',
      laboratory: doc.fileName,
      verifiedDoctor: 'AI draft — pending clinician review',
      date: doc.uploadedAt,
      totalTested: biomarkers.where((b) => b.code != 'OCR').isEmpty
          ? biomarkers.length
          : biomarkers.where((b) => b.code != 'OCR').length,
      outOfRangeCount: outOfRange,
      confidencePercentage: doc.ocrConfidence,
      overallSynthesis: doc.plainLanguageSummary,
      detailedExplanation: doc.detailedExplanation,
      overallUrgency: doc.overallUrgency,
      urgencyBanner: doc.urgencyBanner.isNotEmpty
          ? doc.urgencyBanner
          : (outOfRange > 0
              ? 'Some results look outside the usual range — review with a clinician.'
              : 'Results look within reported ranges — still confirm with your clinician.'),
      recommendedSpecialist: doc.recommendedSpecialist,
      carePlan: doc.carePlan,
      redFlags: doc.redFlags,
      medicineEducation: doc.medicineEducation,
      biomarkers: biomarkers,
      recommendedDoctorQuestions: doc.doctorQuestions,
    );
  }
}
