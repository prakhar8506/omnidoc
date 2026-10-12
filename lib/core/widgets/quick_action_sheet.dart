import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/app_state.dart';
import '../../features/lab_reports/widgets/upload_report_modal.dart';
import '../../features/appointments/widgets/book_appointment_modal.dart';
import '../../features/appointments/screens/find_care_screen.dart';
import '../../features/ai_assistant/widgets/ai_chat_sheet.dart';
import '../../features/womens_health/screens/womens_health_screen.dart';
import '../../features/onboarding/screens/onboarding_baseline_screen.dart';
import '../../features/consent/screens/permission_center_screen.dart';
import '../../features/nutrition/screens/nutrition_hydration_screen.dart';
import '../../features/community/screens/activity_clubs_screen.dart';
import '../../features/wearables/widgets/wearable_permissions_sheet.dart';

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
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomInset),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Actions', style: AppTypography.editorialSm),
                          const SizedBox(height: 2),
                          Text(
                            'Log vitals, record feelings, or consult AI',
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                  icon: Icons.healing_rounded,
                  title: 'Track Symptoms / Clinical Triage',
                  subtitle: 'Describe symptoms and get urgency guidance',
                  color: AppColors.accentCoral,
                  onTap: () {
                    Navigator.pop(context);
                    appState.setTabIndex(2); // Triage tab
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.restaurant_rounded,
                  title: 'Log Meal Entry',
                  subtitle: 'Save what you ate for nutrition tracking',
                  color: AppColors.accentTeal,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NutritionHydrationScreen(appState: appState),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.groups_rounded,
                  title: 'Activity clubs',
                  subtitle: 'Private step and meal competitions with people you invite',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => ActivityClubsScreen(appState: appState),
                      ),
                    );
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
                  subtitle: 'Save a reminder for a visit you have arranged',
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
                  icon: Icons.storefront_rounded,
                  title: 'Find a doctor near me',
                  subtitle: 'Search real clinics in your city by specialty',
                  color: AppColors.accentTeal,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => FindCareScreen(appState: appState),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.directions_run_rounded,
                  title: "Today's Movement & Recovery",
                  subtitle: 'Recovery score (${appState.recoveryScore}%) & personalized exercises',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    appState.setTabIndex(3); // Fitness tab
                    appState.setAppointmentSegment(0); // Movement segment
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.spa_rounded,
                  title: "Women's Health & Pregnancy",
                  subtitle: appState.isPregnancyMode
                      ? 'Week ${appState.gestationalWeeks} • Fetal Kick Counter & Scans'
                      : 'Day ${appState.cycleDay} • ${appState.cyclePhase} & Period Log',
                  color: AppColors.accentRose,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WomensHealthScreen(appState: appState),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.watch_rounded,
                  title: 'Connect Wearable / Health Sync',
                  subtitle: 'Authorize HealthKit or Health Connect permissions',
                  color: AppColors.accentCoral,
                  onTap: () {
                    Navigator.pop(context);
                    WearablePermissionsSheet.show(context, appState);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.sync_rounded,
                  title: 'Sync Vitals from Apple Health / Watch',
                  subtitle: 'Heart rate, deep REM sleep, daily step count',
                  color: AppColors.accentCoral,
                  onTap: () async {
                    Navigator.pop(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final message = await appState.syncVitals();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(message),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceCardDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.shield_rounded,
                  title: 'Privacy & Sensor Permissions',
                  subtitle: 'Coverage ${appState.dataQualityService.computeDataQuality(appState.consentManager).coveragePercentage}% • Granular category toggles',
                  color: AppColors.accentTeal,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PermissionCenterScreen(appState: appState),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionItem(
                  context,
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Update Baseline Health Data',
                  subtitle: 'Recent labs, height, weight, and private progress photo',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnboardingBaselineScreen(
                          appState: appState,
                          onComplete: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
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
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2C3A)
          : Colors.white.withValues(alpha: 0.65),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
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
