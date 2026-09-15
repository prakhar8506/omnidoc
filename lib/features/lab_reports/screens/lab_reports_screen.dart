import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/biomarker_report.dart';
import '../../../core/models/prescription_document.dart';
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
  String? _expandedBiomarkerCode = 'ALT';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final report = widget.appState.activeReport;
        final docs = widget.appState.prescriptions;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context),
              const SizedBox(height: 14),
              _buildDisclaimerBanner(),
              const SizedBox(height: 18),
              if (report == null) ...[
                _buildEmptyUploadCard(context),
              ] else ...[
                _buildActiveReportCard(report),
                const SizedBox(height: 22),
                if (docs.isNotEmpty) ...[
                  const Text('Your Uploads', style: AppTypography.titleLg),
                  const SizedBox(height: 10),
                  ...docs.take(5).map(_buildUploadTile),
                  const SizedBox(height: 22),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('What this means', style: AppTypography.titleLg),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${report.biomarkers.length} Insights',
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
      },
    );
  }

  Widget _buildEmptyUploadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_rounded, size: 42, color: AppColors.primaryContainer),
          const SizedBox(height: 12),
          const Text('No reports yet', style: AppTypography.titleMd),
          const SizedBox(height: 6),
          const Text(
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
            label: const Text('Upload Prescription / Lab', style: TextStyle(fontWeight: FontWeight.w700)),
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
        color: AppColors.surfaceCard,
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.plainLanguageSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
          label: const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          onPressed: () => UploadReportModal.show(context, widget.appState),
        ),
      ],
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
        color: AppColors.surfaceCard,
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
                    Text(report.laboratory, style: AppTypography.labelSm),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: AppColors.accentTeal),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                child: _buildReportMetricTile('Confidence', '${report.confidencePercentage}%', AppColors.textPrimary, AppColors.surfaceContainerLow),
              ),
            ],
          ),
        ],
      ),
    );
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
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
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
                color: isFlagged ? AppColors.accentCoral : AppColors.accentTeal,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(bm.code, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    const SizedBox(width: 6),
                                    Text(bm.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Ref: ${bm.referenceRange}', style: AppTypography.labelSm),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      bm.value,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: isFlagged ? AppColors.accentCoral : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      bm.unit,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isFlagged ? AppColors.accentCoral : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFlagged
                                        ? AppColors.accentCoral.withValues(alpha: 0.15)
                                        : AppColors.accentTeal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isFlagged ? 'Above Range' : 'Optimal',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isFlagged ? AppColors.accentCoral : const Color(0xFF0F766E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        // Plain language summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.psychology_rounded, size: 16, color: AppColors.primaryContainer),
                                  SizedBox(width: 6),
                                  Text('Plain-Language Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bm.plainSummary,
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isFlagged ? Icons.trending_up_rounded : Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: isFlagged ? AppColors.accentCoral : AppColors.accentTeal,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Trend: ${bm.trendText}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isFlagged ? AppColors.accentCoral : AppColors.accentTeal,
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
                            label: Text('Ask AI about ${bm.code}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
        color: AppColors.surfaceCard,
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
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'We generated 4 targeted questions for Dr. Priya Sharma regarding your liver ALT elevation and supplement intake.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
          ),
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
            label: const Text('Prepare Consultation Checklist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            onPressed: () => DoctorQuestionsModal.show(context, report),
          ),
        ],
      ),
    );
  }
}
