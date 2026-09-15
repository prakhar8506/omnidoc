import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/app_state.dart';
import '../../features/lab_reports/widgets/upload_report_modal.dart';
import '../../features/appointments/widgets/book_appointment_modal.dart';
import '../../features/ai_assistant/widgets/ai_chat_sheet.dart';

class QuickActionSheet extends StatelessWidget {
  final AppState appState;

  const QuickActionSheet({
    super.key,
    required this.appState,
  });

  static void show(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionSheet(appState: appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions', style: AppTypography.editorialSm),
                        const SizedBox(height: 2),
                        const Text(
                          'Log vitals, record feelings, or consult AI',
                          style: AppTypography.labelSm,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildActionItem(
                  context,
                  icon: Icons.mood_rounded,
                  title: "Log Today's Mood & Feeling",
                  subtitle: 'Update your mental balance & feeling state',
                  color: AppColors.moodEnergetic,
                  onTap: () {
                    Navigator.pop(context);
                    appState.setTabIndex(1); // Journal tab
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: 'Ask Omni AI Copilot',
                  subtitle: 'Instant clinical explanation & biomarker Q&A',
                  color: AppColors.primaryContainer,
                  onTap: () {
                    Navigator.pop(context);
                    AiChatSheet.show(context, appState);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.upload_file_rounded,
                  title: 'Upload Lab Report or Prescription',
                  subtitle: 'Camera, photo gallery, or medical PDF files',
                  color: AppColors.accentTeal,
                  onTap: () {
                    Navigator.pop(context);
                    appState.setTabIndex(4); // Labs tab
                    UploadReportModal.show(context, appState);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Book Doctor or Video Consultation',
                  subtitle: 'Select from specialist cardiologists, hepatologists',
                  color: AppColors.accentSky,
                  onTap: () {
                    Navigator.pop(context);
                    appState.setTabIndex(3); // Visits tab
                    BookAppointmentModal.show(context, appState);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.sync_rounded,
                  title: 'Sync Vitals from Apple Health / Watch',
                  subtitle: 'Heart rate, deep REM sleep, daily step count',
                  color: AppColors.accentCoral,
                  onTap: () {
                    Navigator.pop(context);
                    appState.syncVitals();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Vitals synchronized with Apple Health data.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceCardDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
