import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/biomarker_report.dart';
import '../../../core/models/prescription_document.dart';
import '../../../core/services/lab_report_pdf.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../widgets/upload_report_modal.dart';
import '../widgets/doctor_questions_modal.dart';
import '../../ai_assistant/widgets/ai_chat_sheet.dart';

class LabReportsScreen extends StatefulWidget {
  final AppState appState;

  const LabReportsScreen({
    super.key,
    required this.appState,
  });

  @override
  State<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends State<LabReportsScreen> {
  String? _expandedBiomarkerCode;
  String? _boundReportId;

  void _ensureExpanded(DiagnosticReport report) {
    if (_boundReportId == report.id && _expandedBiomarkerCode != null) return;
    final flagged = report.biomarkers.where((b) => b.isAttentionFlagged);
    final next = (flagged.isNotEmpty ? flagged.first : report.biomarkers.first).code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _boundReportId = report.id;
        _expandedBiomarkerCode ??= next;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final report = widget.appState.activeReport;
        final docs = widget.appState.prescriptions;
        if (report != null && report.biomarkers.isNotEmpty) {
          _ensureExpanded(report);
        }

        final segment = widget.appState.biologySegmentIndex;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _biologySwitcher(context, segment),
            ),
            Expanded(
              child: segment == 0
                  ? _labsScroll(context, report, docs)
                  : AppointmentsScreen(
                      appState: widget.appState,
                      careSection: segment,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _biologySwitcher(BuildContext context, int segment) {
    Widget pill(int index, String label) {
      final selected = segment == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => widget.appState.setBiologySegment(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          pill(0, 'Labs'),
          pill(1, 'Visits'),
          pill(2, 'Family'),
        ],
      ),
    );
  }

  Widget _labsScroll(BuildContext context, DiagnosticReport? report, List<PrescriptionDocument> docs) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context),
              const SizedBox(height: 14),
              if (widget.appState.labAnalysisProgress > 0 &&
                  widget.appState.labAnalysisProgress < 1) ...[
                _buildLiveProgress(widget.appState.labAnalysisStage, widget.appState.labAnalysisProgress),
                const SizedBox(height: 14),
              ],
              _buildDisclaimerBanner(),
              const SizedBox(height: 18),
              if (report == null) ...[
                _buildEmptyUploadCard(context),
              ] else ...[
                _buildActiveReportCard(report),
                const SizedBox(height: 14),
                _buildUrgencyAndSpecialistCard(report),
                if (report.overallSynthesis.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildPlainLanguageOverview(report),
                ],
                if (report.carePlan.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildBulletCard(
                    title: 'What you can do now',
                    icon: Icons.health_and_safety_outlined,
                    items: report.carePlan,
                    accent: AppColors.accentTeal,
                  ),
                ],
                if (report.medicineEducation.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildBulletCard(
                    title: 'Medicines clinicians often discuss',
                    icon: Icons.medication_outlined,
                    items: [
                      ...report.medicineEducation,
                      'Not a prescription from Cura — confirm every medicine with your doctor.',
                    ],
                    accent: AppColors.accentCoral,
                  ),
                ],
                if (report.redFlags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildBulletCard(
                    title: 'Red flags — seek care sooner',
                    icon: Icons.warning_amber_rounded,
                    items: report.redFlags,
                    accent: AppColors.accentCoral,
                  ),
                ],
                const SizedBox(height: 22),
                if (docs.isNotEmpty) ...[
                  Text('Your Uploads', style: AppTypography.titleLg),
                  const SizedBox(height: 10),
                  ...docs.take(5).map(_buildUploadTile),
                  const SizedBox(height: 22),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Each test, explained', style: AppTypography.titleLg),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${report.biomarkers.length} markers',
                        style: AppTypography.labelSm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...report.biomarkers.map((bm) => _buildBiomarkerCard(bm)),
                const SizedBox(height: 20),
                _buildDoctorQuestionsCard(context, report),
              ],
            ],
          ),
        );
  }

  Widget _buildUrgencyAndSpecialistCard(DiagnosticReport report) {
    final urgent = report.overallUrgency == 'urgent' ||
        report.overallUrgency == 'emergency' ||
        report.overallUrgency == 'soon';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (urgent ? AppColors.accentCoral : AppColors.accentTeal)
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (urgent ? AppColors.accentCoral : AppColors.accentTeal)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                urgent ? Icons.schedule_rounded : Icons.check_circle_outline_rounded,
                size: 18,
                color: urgent ? AppColors.accentCoral : AppColors.accentTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.urgencyBanner.isNotEmpty
                      ? report.urgencyBanner
                      : 'Review timing: ${report.overallUrgency}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.accentCoral : AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Suggested clinician: ${report.recommendedSpecialist}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainLanguageOverview(DiagnosticReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('In plain language', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          Text(
            report.overallSynthesis,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (report.detailedExplanation.isNotEmpty &&
              report.detailedExplanation != report.overallSynthesis) ...[
            const SizedBox(height: 10),
            Text(
              report.detailedExplanation,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.titleMd)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUploadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_rounded, size: 42, color: AppColors.primaryContainer),
          const SizedBox(height: 12),
          Text('No reports yet', style: AppTypography.titleMd),
          const SizedBox(height: 6),
          Text(
            'Upload a prescription or lab report from camera, gallery, or files. We will explain it in plain language.',
            textAlign: TextAlign.center,
            style: AppTypography.labelSm,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: Text('Upload Prescription / Lab', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => UploadReportModal.show(context, widget.appState),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTile(PrescriptionDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.plainLanguageSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CLINICAL INSIGHTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              SizedBox(height: 2),
              Text('Lab Report Interpreter', style: AppTypography.headlineLgMobile),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
          label: Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          onPressed: () => UploadReportModal.show(context, widget.appState),
        ),
      ],
    );
  }

  Widget _buildLiveProgress(String stage, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.isEmpty ? 'Analysing your report' : stage,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.05, 0.98),
            backgroundColor: AppColors.surfaceContainerHigh,
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accentGold, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'General health explanation only • Not a diagnosis • Always review with your physician.',
              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReportCard(DiagnosticReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.primaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: AppTypography.titleMd),
                    const SizedBox(height: 2),
                    Text(
                      report.laboratory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                constraints: const BoxConstraints(maxWidth: 140),
                decoration: BoxDecoration(
                  color: (report.confidencePercentage >= 50
                          ? AppColors.accentTeal
                          : AppColors.accentGold)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: report.confidencePercentage >= 50
                          ? AppColors.accentTeal
                          : AppColors.accentGold,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        report.confidencePercentage >= 50
                            ? 'AI draft — review'
                            : 'Pending review',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportMetricTile('Tested', '${report.totalTested}', AppColors.textPrimary, AppColors.surfaceContainerLow),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReportMetricTile('Out of Range', '${report.outOfRangeCount}', AppColors.accentCoral, AppColors.accentCoral.withValues(alpha: 0.1)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReportMetricTile(
                  'OCR confidence',
                  report.confidencePercentage > 0
                      ? '${report.confidencePercentage}%'
                      : '—',
                  AppColors.textPrimary,
                  AppColors.surfaceContainerLow,
                ),
              ),
            ],
          ),
          if (report.biomarkers.any((b) => b.code != 'OCR')) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openOrCreatePdf(report),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(
                'Open plain-language PDF',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  Future<void> _openOrCreatePdf(DiagnosticReport report) async {
    final path = await LabReportPdf.write(
      userId: widget.appState.userId ?? 'local',
      report: report,
      patientName: widget.appState.userName.isEmpty ? 'Patient' : widget.appState.userName,
    );
    final opened = await LabReportPdf.open(path);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PDF. It was saved in the app documents.')),
      );
    }
  }

  Widget _buildReportMetricTile(String label, String value, Color valueColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiomarkerCard(Biomarker bm) {
    final isExpanded = _expandedBiomarkerCode == bm.code;
    final isFlagged = bm.isAttentionFlagged;
    final isPending = bm.value.toLowerCase().contains('awaiting') ||
        bm.name.toLowerCase().contains('awaiting') ||
        bm.trendText.toLowerCase().contains('awaiting');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status accent bar
              Container(
                width: 5,
                color: isPending
                    ? AppColors.accentGold
                    : (isFlagged ? AppColors.accentCoral : AppColors.accentTeal),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedBiomarkerCode = isExpanded ? null : bm.code;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPending ? 'Processing' : bm.code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPending
                                        ? 'OCR & AI analysis in progress'
                                        : bm.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ref: ${bm.referenceRange}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSm,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isPending)
                                    const Icon(
                                      Icons.hourglass_top_rounded,
                                      size: 22,
                                      color: AppColors.accentGold,
                                    )
                                  else
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            bm.value,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: isFlagged
                                                  ? AppColors.accentCoral
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          if (bm.unit.isNotEmpty) ...[
                                            const SizedBox(width: 2),
                                            Text(
                                              bm.unit,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isFlagged
                                                    ? AppColors.accentCoral
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? AppColors.accentGold.withValues(alpha: 0.15)
                                          : isFlagged
                                              ? AppColors.accentCoral.withValues(alpha: 0.15)
                                              : AppColors.accentTeal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isPending
                                          ? 'Pending'
                                          : bm.trendText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isPending
                                            ? const Color(0xFFB45309)
                                            : isFlagged
                                                ? AppColors.accentCoral
                                                : const Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.psychology_rounded, size: 16, color: AppColors.primaryContainer),
                                  SizedBox(width: 6),
                                  Text('What this test measures', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bm.plainSummary,
                                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
                              ),
                              if (bm.whatItMeans.isNotEmpty || bm.clinicalContext.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('What your number means', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                const SizedBox(height: 4),
                                Text(
                                  bm.whatItMeans.isNotEmpty ? bm.whatItMeans : bm.clinicalContext,
                                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
                                ),
                              ],
                              if (bm.possibleCauses.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('What can cause this', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                ...bm.possibleCauses.map((c) => Text('• $c', style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary))),
                              ],
                              if (bm.lifestyleMeasures.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Lifestyle measures', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                ...bm.lifestyleMeasures.map((c) => Text('• $c', style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary))),
                              ],
                              if (bm.precautions.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Precautions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                ...bm.precautions.map((c) => Text('• $c', style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary))),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'See: ${bm.specialist} · Urgency: ${bm.consultUrgency}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryContainer),
                              ),
                              if (bm.commonlyDiscussedMedicines.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Medicines often discussed (not a prescription)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                ...bm.commonlyDiscussedMedicines.map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• ${m.name} — ${m.whyDiscussed}. ${m.note}',
                                      style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isPending
                                        ? Icons.schedule_rounded
                                        : isFlagged
                                            ? Icons.trending_up_rounded
                                            : Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: isPending
                                        ? AppColors.accentGold
                                        : isFlagged
                                            ? AppColors.accentCoral
                                            : AppColors.accentTeal,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Status: ${bm.trendText}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isPending
                                            ? AppColors.accentGold
                                            : isFlagged
                                                ? AppColors.accentCoral
                                                : AppColors.accentTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: AppColors.primaryContainer),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                            label: Text('Ask AI about ${bm.code}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              AiChatSheet.show(context, widget.appState);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorQuestionsCard(BuildContext context, DiagnosticReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryContainer, size: 20),
                  SizedBox(width: 8),
                  Text('Doctor Discussion Prep', style: AppTypography.titleMd),
                ],
              ),
              TextButton(
                onPressed: () => DoctorQuestionsModal.show(context, report),
                child: Text('View All', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.recommendedDoctorQuestions.isEmpty
                ? 'Ask your ${report.recommendedSpecialist} to walk through these results with you.'
                : 'We prepared ${report.recommendedDoctorQuestions.length} questions for your ${report.recommendedSpecialist} based on this report.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
          ),
          if (report.recommendedDoctorQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...report.recommendedDoctorQuestions.take(3).map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $q',
                      style: TextStyle(fontSize: 12.5, height: 1.35, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLow,
              foregroundColor: AppColors.primaryContainer,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: Text('Prepare Consultation Checklist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            onPressed: () => DoctorQuestionsModal.show(context, report),
          ),
        ],
      ),
    );
  }
}
