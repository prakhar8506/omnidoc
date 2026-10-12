import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/prescription_document.dart';
import '../../../core/services/report_interpreter_service.dart';
import '../../premium/premium_screen.dart';

class UploadReportModal extends StatefulWidget {
  final AppState appState;

  const UploadReportModal({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    if (!appState.hasPremium) {
      PremiumScreen.show(context, appState);
      return Future.value();
    }
    return showModalBottomSheet(
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
  final _picker = ImagePicker();
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  String _statusText = 'Ready to analyze document';
  String? _previewPath;
  String? _errorText;

  Future<void> _pickFromCamera() async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (shot == null) return;
      await _processPickedPath(
        path: shot.path,
        name: shot.name.isNotEmpty ? shot.name : 'camera_prescription.jpg',
        source: PrescriptionSource.camera,
        isImage: true,
      );
    } catch (e) {
      _showPickError('Camera unavailable. Check permissions or try gallery.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (shot == null) return;
      await _processPickedPath(
        path: shot.path,
        name: shot.name.isNotEmpty ? shot.name : 'gallery_prescription.jpg',
        source: PrescriptionSource.gallery,
        isImage: true,
      );
    } catch (e) {
      _showPickError('Could not open gallery. Check photo permissions.');
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'webp'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final isImage = !(file.name.toLowerCase().endsWith('.pdf'));

      if (kIsWeb || file.path == null) {
        final bytes = await file.readAsBytes();
        final userId = widget.appState.userId;
        if (userId == null) {
          _showPickError('Please sign in again.');
          return;
        }
        setState(() {
          _isProcessing = true;
          _uploadProgress = 0.2;
          _statusText = 'Saving your document...';
          _errorText = null;
        });
        String destPath = file.name;
        if (!kIsWeb) {
          final dir = await ReportInterpreterService.userDocsDir(userId);
          final safeName = file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
          destPath = p.join(dir, '${DateTime.now().millisecondsSinceEpoch}_$safeName');
          try {
            await File(destPath).writeAsBytes(bytes);
          } catch (_) {}
        }
        await _finishInterpretation(
          path: destPath,
          name: file.name,
          source: PrescriptionSource.files,
          isImage: isImage,
          fileBytes: Uint8List.fromList(bytes),
        );
        return;
      }

      await _processPickedPath(
        path: file.path!,
        name: file.name,
        source: PrescriptionSource.files,
        isImage: isImage,
      );
    } catch (e) {
      _showPickError('Could not open files. Try another format (PDF/JPG/PNG).');
    }
  }

  Future<void> _processPickedPath({
    required String path,
    required String name,
    required PrescriptionSource source,
    required bool isImage,
  }) async {
    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.15;
      _statusText = 'Saving your document...';
      _previewPath = isImage ? path : null;
      _errorText = null;
    });

    try {
      Uint8List? bytes;
      if (!kIsWeb) {
        try {
          bytes = await File(path).readAsBytes();
        } catch (_) {}
      }
      await _finishInterpretation(
        path: path,
        name: name,
        source: source,
        isImage: isImage,
        fileBytes: bytes,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorText = 'Upload failed. Please try again.';
      });
    }
  }

  Future<void> _finishInterpretation({
    required String path,
    required String name,
    required PrescriptionSource source,
    required bool isImage,
    Uint8List? fileBytes,
  }) async {
    if (!mounted) return;
    setState(() {
      _uploadProgress = 0.45;
      _statusText = 'AI is reading every value on your report…';
    });

    final doc = await widget.appState.uploadHealthDocument(
      sourcePath: path,
      originalName: name,
      source: source,
      isImage: isImage,
      fileBytes: fileBytes,
    );

    if (!mounted) return;
    setState(() {
      _uploadProgress = 1.0;
      _statusText = doc.analysisStatus == 'ready'
          ? 'Your plain-language PDF is ready'
          : doc.plainLanguageSummary;
    });
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.pop(context);
    widget.appState.setTabIndex(4);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          doc.analysisStatus == 'ready'
              ? 'Lab analysis ready for “${doc.fileName}”'
              : 'Uploaded “${doc.fileName}”. ${doc.plainLanguageSummary}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPickError(String message) {
    if (!mounted) return;
    setState(() => _errorText = message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
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
                const Expanded(
                  child: Text(
                    'Upload Prescription / Lab',
                    style: AppTypography.titleLg,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isProcessing ? _buildProcessing() : _buildPickerOptions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    const stages = [
      'Analysing your report',
      'Reading each test and number',
      'Calculating what is normal, mild, or severe',
      'Contemplating causes, precautions, and which doctor to see',
      'Writing the explanation in simple words',
      'Building your plain-language PDF',
    ];
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final live = widget.appState.labAnalysisStage;
        final progress = widget.appState.labAnalysisProgress > 0
            ? widget.appState.labAnalysisProgress
            : _uploadProgress;
        final current = live.isNotEmpty ? live : _statusText;
        return Column(
          children: [
            if (_previewPath != null && !kIsWeb) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_previewPath!),
                  height: 96,
                  width: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(current, style: AppTypography.titleMd, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.05, 1),
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 16),
            ...stages.map((stage) {
              final reached = current.toLowerCase().contains(stage.split(' ').first.toLowerCase()) ||
                  progress >= _stageFloor(stage);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 16,
                      color: reached ? AppColors.accentTeal : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                          color: reached ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  double _stageFloor(String stage) {
    switch (stage) {
      case 'Analysing your report':
        return 0.3;
      case 'Reading each test and number':
        return 0.4;
      case 'Calculating what is normal, mild, or severe':
        return 0.52;
      case 'Contemplating causes, precautions, and which doctor to see':
        return 0.64;
      case 'Writing the explanation in simple words':
        return 0.74;
      default:
        return 0.9;
    }
  }

  Widget _buildPickerOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.medication_liquid_rounded,
              color: AppColors.primaryContainer, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          'Upload a prescription or lab report',
          textAlign: TextAlign.center,
          style: AppTypography.titleMd,
        ),
        const SizedBox(height: 6),
        Text(
          'We will save it to your account and explain it in plain language so you can discuss it with your doctor.',
          textAlign: TextAlign.center,
          style: AppTypography.labelSm,
        ),
        const SizedBox(height: 22),
        _optionTile(
          icon: Icons.photo_camera_rounded,
          title: 'Take Photo',
          subtitle: 'Use your camera to scan a paper Rx or report',
          onTap: _pickFromCamera,
        ),
        _optionTile(
          icon: Icons.photo_library_outlined,
          title: 'Choose from Gallery',
          subtitle: 'Pick an existing photo from your library',
          onTap: _pickFromGallery,
        ),
        _optionTile(
          icon: Icons.folder_open_rounded,
          title: 'Browse Files',
          subtitle: 'PDF or image from Downloads / Files',
          onTap: _pickFromFiles,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accentCoral,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
