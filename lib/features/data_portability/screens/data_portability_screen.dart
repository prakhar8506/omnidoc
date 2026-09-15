import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';
import '../services/data_export_service.dart';

class DataPortabilityScreen extends StatefulWidget {
  final AppState appState;

  const DataPortabilityScreen({
    super.key,
    required this.appState,
  });

  @override
  State<DataPortabilityScreen> createState() => _DataPortabilityScreenState();
}

class _DataPortabilityScreenState extends State<DataPortabilityScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HolographicBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BouncingTap(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        ),
                      ),
                      Text('Export Health Records', style: AppTypography.editorialSm),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero Information Card
                    GlassContainer(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.file_download_rounded, color: AppColors.primaryContainer, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DATA SOVEREIGNTY & PORTABILITY',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryContainer, letterSpacing: 0.8),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Complete Medical History',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Export your vitals history, active prescriptions, doctor notes, and diagnostic lab biomarkers in standardized formats to share with your healthcare team.',
                            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                          ),
                          const SizedBox(height: 20),

                          // Download PDF Action Button
                          BouncingTap(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _isExporting = true);
                              final file = await DataExportService.generateClinicalPdf(widget.appState);
                              if (mounted) {
                                setState(() => _isExporting = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(file != null
                                        ? 'Clinical PDF document generated: ${file.path.split('/').last}'
                                        : 'Clinical PDF summary compiled successfully!'),
                                    backgroundColor: AppColors.accentTeal,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textPrimary.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isExporting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Download Clinical Summary PDF',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Exported Health Package Overview
                    const Text(
                      'Included in Your Clinical Export',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    _buildExportItem(
                      icon: Icons.monitor_heart_rounded,
                      title: 'Physiological Vitals Telemetry',
                      subtitle: 'Resting Heart Rate, Sleep Quality, Blood Oxygen, and Daily Movement trends.',
                      color: AppColors.watchHeartRate,
                    ),
                    const SizedBox(height: 10),

                    _buildExportItem(
                      icon: Icons.medication_rounded,
                      title: 'Prescriptions & Regimen',
                      subtitle: '${widget.appState.medications.length} active medications with dosing schedule and clinical instructions.',
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 10),

                    _buildExportItem(
                      icon: Icons.biotech_rounded,
                      title: 'Diagnostic Lab Biomarkers',
                      subtitle: 'Comprehensive metabolic and liver enzyme panels with clinical reference ranges.',
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 10),

                    _buildExportItem(
                      icon: Icons.calendar_month_rounded,
                      title: 'Clinical Consultations & Care Plan',
                      subtitle: '${widget.appState.appointments.length} recorded specialist consultations, clinician instructions, and prep notes.',
                      color: AppColors.accentTeal,
                    ),
                    const SizedBox(height: 10),

                    _buildExportItem(
                      icon: Icons.emergency_rounded,
                      title: 'Emergency Medical ID',
                      subtitle: 'Blood type (${widget.appState.bloodType}), registered emergency contacts, and organ donor registry status.',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 24),

                    // Primary Action: Save to Files
                    BouncingTap(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isExporting = true);
                        final result = await DataExportService.saveClinicalPdf(widget.appState);
                        if (mounted) {
                          setState(() => _isExporting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(result != null
                                  ? 'Clinical Summary PDF saved: ${result.split('/').last}'
                                  : 'Clinical Summary PDF exported successfully!'),
                              backgroundColor: AppColors.accentTeal,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isExporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.folder_special_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Save Clinical Summary to Files',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary.withValues(alpha: 0.95)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
