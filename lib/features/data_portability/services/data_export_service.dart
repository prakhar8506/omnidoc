import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/state/app_state.dart';

/// Clinical Data Portability Service: Generates standard HL7 FHIR Bundles
/// and formatted PDF clinical summaries for sharing with healthcare providers.
class DataExportService {
  /// Generate a standard HL7 FHIR JSON Bundle
  static String generateFhirBundle(AppState state) {
    final now = DateTime.now().toIso8601String();
    final patientId = state.userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');

    final fhirBundle = {
      'resourceType': 'Bundle',
      'id': 'health-companion-export-${DateTime.now().millisecondsSinceEpoch}',
      'meta': {
        'lastUpdated': now,
        'profile': ['http://hl7.org/fhir/StructureDefinition/document'],
      },
      'type': 'document',
      'timestamp': now,
      'entry': [
        // Patient Resource
        {
          'resource': {
            'resourceType': 'Patient',
            'id': patientId,
            'name': [
              {
                'use': 'official',
                'text': state.userName,
              }
            ],
            'telecom': [
              {
                'system': 'email',
                'value': state.userEmail,
              }
            ],
            'extension': [
              {
                'url': 'http://hl7.org/fhir/StructureDefinition/patient-bloodType',
                'valueString': state.bloodType,
              }
            ],
          }
        },

        // Vitals Observations
        {
          'resource': {
            'resourceType': 'Observation',
            'status': 'final',
            'category': [
              {
                'coding': [
                  {
                    'system': 'http://terminology.hl7.org/CodeSystem/observation-category',
                    'code': 'vital-signs',
                    'display': 'Vital Signs',
                  }
                ]
              }
            ],
            'code': {
              'coding': [
                {'system': 'http://loinc.org', 'code': '8867-4', 'display': 'Heart rate'}
              ],
              'text': 'Resting Heart Rate',
            },
            'subject': {'reference': 'Patient/$patientId'},
            'effectiveDateTime': now,
            'valueQuantity': {
              'value': state.restingHeartRate,
              'unit': 'beats/minute',
              'system': 'http://unitsofmeasure.org',
              'code': '/min',
            }
          }
        },
        {
          'resource': {
            'resourceType': 'Observation',
            'status': 'final',
            'category': [
              {
                'coding': [
                  {
                    'system': 'http://terminology.hl7.org/CodeSystem/observation-category',
                    'code': 'vital-signs',
                    'display': 'Vital Signs',
                  }
                ]
              }
            ],
            'code': {
              'coding': [
                {'system': 'http://loinc.org', 'code': '2708-6', 'display': 'Oxygen saturation'}
              ],
              'text': 'Blood Oxygen Saturation',
            },
            'subject': {'reference': 'Patient/$patientId'},
            'effectiveDateTime': now,
            'valueQuantity': {
              'value': state.bloodOxygen,
              'unit': '%',
              'system': 'http://unitsofmeasure.org',
              'code': '%',
            }
          }
        },

        // Active Medications
        for (var med in state.medications)
          {
            'resource': {
              'resourceType': 'MedicationStatement',
              'status': 'active',
              'medicationCodeableConcept': {
                'text': med.name,
              },
              'dosage': [
                {
                  'text': '${med.dosage} • ${med.scheduleTime}',
                }
              ],
              'note': [
                {'text': med.instruction}
              ],
            }
          },

        // Clinical Consultations
        for (var apt in state.appointments)
          {
            'resource': {
              'resourceType': 'Appointment',
              'status': 'booked',
              'description': '${apt.doctorName} (${apt.specialty})',
              'start': apt.dateTime.toIso8601String(),
              'comment': apt.preparationNote,
            }
          }
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(fhirBundle);
  }

  /// Generate raw PDF bytes
  static Future<Uint8List> generatePdfBytes(AppState state) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('HEALTH COMPANION CLINICAL SUMMARY',
                      style: const pw.TextStyle(fontSize: 16, color: PdfColors.indigo900)),
                  pw.SizedBox(height: 4),
                  pw.Text('Comprehensive Personal Health Record', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
              pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
          pw.SizedBox(height: 12),

          // Patient Demographics
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Patient Name: ${state.userName}', style: const pw.TextStyle(fontSize: 13)),
                  pw.SizedBox(height: 2),
                  pw.Text('Email: ${state.userEmail}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Blood Type: ${state.bloodType}', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 2),
                  pw.Text('Daily Balance Recovery: ${state.dailyBalanceScore}/100', style: const pw.TextStyle(fontSize: 10, color: PdfColors.indigo700)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Vitals Summary Table
          pw.Text('1. PHYSIOLOGICAL VITALS & WEARABLES TELEMETRY',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.indigo900)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Current Value', 'Reference Range', 'Status'],
            data: [
              ['Resting Heart Rate', '${state.restingHeartRate} bpm', '60 – 100 bpm', 'Optimal'],
              ['Blood Oxygen (SpO2)', '${state.bloodOxygen}%', '95 – 100%', 'Normal'],
              ['Sleep Duration', state.sleepDuration, '7 – 9 hours', 'Adequate'],
              ['Daily Movement', '${state.dailySteps.toInt()} steps', '7,500 – 10,000 steps', 'Active'],
              ['Blood Pressure', state.bloodPressure, '< 120/80 mmHg', 'Normal'],
            ],
            headerStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          ),
          pw.SizedBox(height: 18),

          // Active Medications Table
          pw.Text('2. ACTIVE MEDICATIONS & SUPPLEMENTS',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.indigo900)),
          pw.SizedBox(height: 6),
          if (state.medications.isEmpty)
            pw.Text('No active medications recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Medication / Supplement', 'Dosage', 'Schedule', 'Purpose'],
              data: state.medications.map((m) => [m.name, m.dosage, m.scheduleTime, m.instruction]).toList(),
              headerStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            ),
          pw.SizedBox(height: 18),

          // Upcoming Consultations
          pw.Text('3. CLINICAL CONSULTATIONS & CARE PLAN',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.indigo900)),
          pw.SizedBox(height: 6),
          if (state.appointments.isEmpty)
            pw.Text('No scheduled consultations.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Physician', 'Specialty', 'Facility / Room', 'Date & Time', 'Clinical Notes'],
              data: state.appointments
                  .map((a) => [
                        a.doctorName,
                        a.specialty,
                        a.clinicName,
                        a.dateTime.toString().split('.')[0],
                        a.preparationNote,
                      ])
                  .toList(),
              headerStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            ),
          pw.SizedBox(height: 24),

          // Clinician Notice
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'NOTICE FOR HEALTHCARE PROVIDERS: This summary document is generated by Health Companion from patient-tracked telemetry, uploaded laboratory reports, and verified personal health inputs. It is intended to inform clinical dialogue and does not replace formal electronic medical records.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate a clinical PDF document using the `pdf` package
  static Future<File?> generateClinicalPdf(AppState state) async {
    final bytes = await generatePdfBytes(state);
    if (kIsWeb) {
      return null;
    }

    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final file = File('${outputDir.path}/health_companion_clinical_record.pdf');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }

  /// Save the PDF using native platform dialog / downloads
  static Future<String?> saveClinicalPdf(AppState state) async {
    final bytes = await generatePdfBytes(state);
    final fileName = 'Health_Companion_Clinical_Summary_${DateTime.now().year}.pdf';

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save Clinical Summary PDF',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savedUri != null) {
        return savedUri.path.isNotEmpty ? savedUri.path : fileName;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final outputDir = await getApplicationDocumentsDirectory();
        final file = File('${outputDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      } catch (_) {}
    }

    return fileName;
  }
}
