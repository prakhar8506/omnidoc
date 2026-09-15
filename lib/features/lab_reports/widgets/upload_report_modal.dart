import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';

class UploadReportModal extends StatefulWidget {
  final AppState appState;

  const UploadReportModal({super.key, required this.appState});

  static void show(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadReportModal(appState: appState),
    );
  }

  @override
  State<UploadReportModal> createState() => _UploadReportModalState();
}

class _UploadReportModalState extends State<UploadReportModal> {
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  String _statusText = 'Ready to analyze document';

  void _simulateUpload() async {
    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.15;
      _statusText = 'Extracting text via HIPAA OCR...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _uploadProgress = 0.60;
      _statusText = 'Normalizing reference ranges & biomarker codes...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _uploadProgress = 1.0;
      _statusText = 'Clinical synthesis ready!';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('New Diagnostic Report successfully analyzed with 99% confidence!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upload Diagnostic Lab', style: AppTypography.titleLg),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing) ...[
                    const SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      style: AppTypography.titleMd,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.primaryContainer,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Import Medical PDF or Lab Photo', style: AppTypography.titleMd),
                    const SizedBox(height: 6),
                    const Text(
                      'Supports Quest Diagnostics, Labcorp, Hospital EHR exports, and camera captures.',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSm,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryContainer),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryContainer),
                            label: const Text('Scan Photo', style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w700)),
                            onPressed: _simulateUpload,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.file_upload_outlined, size: 18),
                            label: const Text('Select PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: _simulateUpload,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
