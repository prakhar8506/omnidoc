import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _fhirJsonPreview;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fhirJsonPreview = DataExportService.generateFhirBundle(widget.appState);
  }

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

                    // FHIR JSON Standard Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HL7 FHIR Document Bundle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        BouncingTap(
                          onTap: () {
                            if (_fhirJsonPreview != null) {
                              Clipboard.setData(ClipboardData(text: _fhirJsonPreview!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('FHIR JSON bundle copied to clipboard!'),
                                  backgroundColor: AppColors.accentTeal,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Copy JSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // FHIR Code Viewer
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161522),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _fhirJsonPreview ?? '// Generating FHIR bundle...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.45,
                            color: Color(0xFF81D4FA),
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
}
