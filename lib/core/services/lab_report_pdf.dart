import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/biomarker_report.dart';

/// Plain-language PDF of a lab analysis. Text only, written for non-clinicians.
class LabReportPdf {
  static const _channel = MethodChannel('cura/health_connect');

  static Future<bool> open(String path) async {
    if (path.isEmpty || kIsWeb) return false;
    try {
      final opened = await _channel.invokeMethod<bool>('openPdf', {'path': path});
      return opened == true;
    } catch (e) {
      debugPrint('[LabReportPdf] open failed: $e');
      return false;
    }
  }

  static Future<String> write({
    required String userId,
    required DiagnosticReport report,
    String patientName = 'Patient',
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'cura', userId, 'reports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final safeId = report.id.replaceAll(RegExp(r'[^\w\-]'), '_');
    final path = p.join(dir.path, '$safeId.pdf');

    final doc = pw.Document(theme: await _theme());
    final date = DateFormat('d MMM yyyy, h:mm a').format(report.date);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'Your lab report, in plain language',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Prepared for $patientName', style: const pw.TextStyle(fontSize: 12)),
          pw.Text(date, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(
            'Source file: ${report.laboratory}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'This is an educational explanation, not a diagnosis or a prescription. '
              'A licensed doctor must confirm these results before you start or stop any medicine.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('How soon to see a doctor', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(report.urgencyBanner, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Suggested clinician: ${report.recommendedSpecialist}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Tests read: ${report.totalTested}    Outside the usual range: ${report.outOfRangeCount}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Text('The short version', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(report.overallSynthesis, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
          if (report.detailedExplanation.isNotEmpty &&
              report.detailedExplanation != report.overallSynthesis) ...[
            pw.SizedBox(height: 8),
            pw.Text(report.detailedExplanation, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
          ],
          if (report.carePlan.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('What you can do now', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...report.carePlan.map((item) => pw.Bullet(text: item, style: const pw.TextStyle(fontSize: 11))),
          ],
          if (report.redFlags.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Get help sooner if you notice', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...report.redFlags.map((item) => pw.Bullet(text: item, style: const pw.TextStyle(fontSize: 11))),
          ],
          if (report.medicineEducation.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Medicines doctors often discuss (not a prescription)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...report.medicineEducation.map((item) => pw.Bullet(text: item, style: const pw.TextStyle(fontSize: 11))),
          ],
          pw.SizedBox(height: 18),
          pw.Text('Each test, explained', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...report.biomarkers.where((b) => b.code != 'OCR').expand(_markerBlocks),
          if (report.recommendedDoctorQuestions.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Questions to ask your doctor', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...report.recommendedDoctorQuestions.map(
              (q) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $q', style: const pw.TextStyle(fontSize: 11)),
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'Generated by Cura from the uploaded file. Values are taken from that document. '
            'If a number looks wrong, compare it with the original paper report.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await doc.save(), flush: true);
    return path;
  }

  /// System Roboto covers lab units and punctuation (×, µ, —, •) that the
  /// built-in PDF font drops.
  static Future<pw.ThemeData?> _theme() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final file = File('/system/fonts/Roboto-Regular.ttf');
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final font = pw.Font.ttf(ByteData.sublistView(bytes));
      return pw.ThemeData.withFont(base: font, bold: font);
    } catch (e) {
      debugPrint('[LabReportPdf] font: $e');
      return null;
    }
  }

  static List<pw.Widget> _markerBlocks(Biomarker bm) {
    final value = '${bm.value}${bm.unit.isNotEmpty ? ' ${bm.unit}' : ''}';
    final lines = <String>[
      'Your result: $value',
      'Usual range: ${bm.referenceRange}',
      'Status: ${bm.trendText}',
      if (bm.plainSummary.isNotEmpty) 'What this test is: ${bm.plainSummary}',
      if (bm.whatItMeans.isNotEmpty) 'What your number means: ${bm.whatItMeans}',
      if (bm.possibleCauses.isNotEmpty) 'What can cause this: ${bm.possibleCauses.join('; ')}',
      if (bm.lifestyleMeasures.isNotEmpty) 'Measures that help: ${bm.lifestyleMeasures.join('; ')}',
      if (bm.precautions.isNotEmpty) 'Precautions: ${bm.precautions.join('; ')}',
      'See: ${bm.specialist}. How soon: ${bm.consultUrgency}.',
    ];
    if (bm.commonlyDiscussedMedicines.isNotEmpty) {
      lines.add(
        'Medicines often discussed: ${bm.commonlyDiscussedMedicines.map((m) => '${m.name} — ${m.whyDiscussed}. ${m.note}').join(' ')}',
      );
    }
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${bm.name} (${bm.code})',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(line, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
