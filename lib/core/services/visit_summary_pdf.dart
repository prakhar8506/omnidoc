import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../care/visit_record.dart';

Future<List<int>> buildVisitSummaryPdf({
  required String patientName,
  required List<String> allergies,
  required List<String> conditions,
  required List<Map<String, dynamic>> profileMedicines,
  required List<Map<String, dynamic>> doseLogs,
  required List<Map<String, dynamic>> sickPeriods,
  required List<Map<String, dynamic>> sickDays,
}) async {
  final blocks = buildVisitBlocks(
    patientName: patientName,
    allergies: allergies,
    conditions: conditions,
    profileMedicines: profileMedicines,
    doseLogs: doseLogs,
    sickPeriods: sickPeriods,
    sickDays: sickDays,
  );
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text('Cura visit summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Prepared ${DateTime.now().toIso8601String().split('.').first}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
        pw.Text(visitDisclaimer, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        pw.SizedBox(height: 16),
        pw.Text('Medicines logged on ordinary days', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (doseLogs.isEmpty)
          pw.Text('None logged yet.', style: const pw.TextStyle(fontSize: 11))
        else
          pw.TableHelper.fromTextArray(
            headers: ['When', 'Medicine', 'Amount'],
            data: [
              for (final dose in doseLogs)
                [
                  dose['takenAt']?.toString() ?? '',
                  dose['name']?.toString() ?? '',
                  (dose['amount'] ?? '').toString(),
                ],
            ],
            headerStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        pw.SizedBox(height: 12),
        pw.Text('Taken during a marked sick week', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (_sickMedicines(sickDays).isEmpty)
          pw.Text('None logged yet.', style: const pw.TextStyle(fontSize: 11))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Day', 'Medicine', 'Amount'],
            data: _sickMedicines(sickDays),
            headerStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        pw.SizedBox(height: 16),
        for (final block in blocks) ...[
          pw.Text(block.title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          for (final line in block.lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
            ),
          pw.SizedBox(height: 12),
        ],
      ],
    ),
  );
  return pdf.save();
}

List<List<String>> _sickMedicines(List<Map<String, dynamic>> sickDays) {
  final rows = <List<String>>[];
  for (final day in sickDays) {
    for (final raw in (day['items'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      if (item['kind'] != 'medicine') continue;
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      rows.add([day['day']?.toString() ?? '', name, (item['amount'] ?? '').toString()]);
    }
  }
  return rows;
}
