import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';
import '../../lab_reports/widgets/upload_report_modal.dart';

class OnboardingBaselineScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onComplete;

  const OnboardingBaselineScreen({
    super.key,
    required this.appState,
    this.onComplete,
  });

  @override
  State<OnboardingBaselineScreen> createState() => _OnboardingBaselineScreenState();
}

class _OnboardingBaselineScreenState extends State<OnboardingBaselineScreen> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _progressPhotoPath;
  bool _labUploaded = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.appState.userHeightCm?.toStringAsFixed(0) ?? '172',
    );
    _weightController = TextEditingController(
      text: widget.appState.userWeightKg?.toStringAsFixed(1) ?? '65.0',
    );
    _progressPhotoPath = widget.appState.baselineProgressPhotoPath;
    _labUploaded = widget.appState.prescriptions.isNotEmpty;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickProgressPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source, maxWidth: 1080);
      if (photo != null) {
        setState(() => _progressPhotoPath = photo.path);
      }
    } catch (_) {}
  }

  void _finishOnboarding() {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);

    widget.appState.saveBaselineData(
      heightCm: h,
      weightKg: w,
      photoPath: _progressPhotoPath,
    );

    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HolographicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Step 2 of 2 • Baseline Setup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Editorial Title
                const Text(
                  'Establish your\nclinical baseline',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Optional telemetry to personalize your daily balance, recovery score, and biomarker ranges.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Card 1: Recent Lab Upload (Skippable)
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.description_rounded, color: Color(0xFF6366F1), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text('Recent Lab or Bloodwork', style: AppTypography.titleMd),
                            ],
                          ),
                          if (_labUploaded || widget.appState.prescriptions.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Uploaded',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload a PDF or photo of recent bloodwork (CBC, CMP, Lipids). Our AI will extract your reference ranges.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          UploadReportModal.show(context, widget.appState);
                          setState(() => _labUploaded = true);
                        },
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          _labUploaded || widget.appState.prescriptions.isNotEmpty
                              ? 'Upload Another Document'
                              : 'Upload Recent Lab / Prescription',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryContainer,
                          side: const BorderSide(color: AppColors.surfaceContainerHigh),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Body Weight & Height
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.straighten_rounded, color: Color(0xFF0EA5E9), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text('Body Metrics', style: AppTypography.titleMd),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Height (cm)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                suffixText: 'cm',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                suffixText: 'kg',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 3: Baseline Progress Photo (Privacy First)
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF8B5CF6), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text('Baseline Progress Photo', style: AppTypography.titleMd),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keep an optional private photo to document posture, body composition, or physical recovery over time.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 10),
                      // Privacy Guarantee Badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 16, color: Color(0xFF15803D)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Privacy Guaranteed: Encrypted on-device only. Never shared to community feeds or cloud servers.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_progressPhotoPath != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: !kIsWeb
                                  ? Image.file(
                                      File(_progressPhotoPath!),
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 140,
                                      width: double.infinity,
                                      color: AppColors.surfaceBright,
                                      child: const Icon(Icons.image_rounded, size: 48),
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _progressPhotoPath = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickProgressPhoto(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                label: const Text('Take Photo'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: AppColors.surfaceContainerHigh),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickProgressPhoto(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 18),
                                label: const Text('Gallery'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: AppColors.surfaceContainerHigh),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Complete Button
                ElevatedButton(
                  onPressed: _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Complete Setup & Enter Dashboard',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
