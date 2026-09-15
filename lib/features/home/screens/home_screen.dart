import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../appointments/widgets/book_appointment_modal.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;

  const HomeScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference Screen 1 Header: Daily Balance & Circular Gauge
              _buildDailyBalanceHeader(context),
              const SizedBox(height: 20),

              // Ambient Hero Card: Tip + Active pill + Weather pill
              _buildAmbientWellnessCard(context),
              const SizedBox(height: 20),

              // Reference Screen 1: Today's Stress Card (Highest 36, Lowest 6, Average 11, sparkline bar graph)
              _buildTodayStressCard(context),
              const SizedBox(height: 20),

              // Vitals Dashboard (Heart, Sleep, Steps)
              _buildVitalsDashboard(context),
              const SizedBox(height: 20),

              // Medication Schedule
              _buildMedicationTracker(context),
              const SizedBox(height: 20),

              // Upcoming Consultation Preview
              _buildUpcomingConsultation(context),
              const SizedBox(height: 20),

              // Quick Access Grid
              _buildQuickActions(context),
            ],
          ),
        );
      },
    );
  }

  /// Screen 1 Header: "Daily Balance" with semi-circular balance gauge ("78 / 100", "Good balance")
  Widget _buildDailyBalanceHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appState.firstName.isNotEmpty) ...[
              Text(
                'Good morning, ${appState.firstName}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text('Daily Balance', style: AppTypography.editorialLg),
            const SizedBox(height: 4),
            Text(
              'Your body state today',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        // Semi-circular gauge (Reference: "78 / 100", "Good balance")
        GestureDetector(
          onTap: () => appState.setTabIndex(1), // Open feeling journal
          child: Container(
            width: 110,
            height: 72,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 55),
                  painter: _BalanceArcGaugePainter(
                    score: appState.dailyBalanceScore,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${appState.dailyBalanceScore}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        appState.balanceStatus,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Ambient Wellness Card with Glowing Gradient Mesh, Tip pill, Active pill, Weather pill
  Widget _buildAmbientWellnessCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8E5FE),
            Color(0xFFFDE8EF),
            Color(0xFFEDE0FA),
          ],
        ),
        boxShadow: AppColors.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Frosted Tip Pill (Reference: "💡 Tip: Today is good for light cardio or yoga")
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.accentGold,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Today is good for light cardio or yoga',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary.withValues(alpha: 0.9),
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Dual Pills: Activity Selector + Weather & Temperature
                Row(
                  children: [
                    // Activity Pill (Reference: "🏃 Active ⌵")
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Quick activity status toggle
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Activity mode: Active cardio tracked via Apple Health.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.surfaceCardDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_run_rounded,
                                  color: AppColors.primaryContainer,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Weather Pill (Reference: "30 °C Hot and Sunny")
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_sunny_rounded,
                              color: AppColors.accentGold,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '30 °C',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Hot & Sunny',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Screen 1 Stress Card: "Today's stress", "Last updated at 07:54 AM", 36 Highest / 6 Lowest / 11 Average + sparkline bar
  Widget _buildTodayStressCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's stress",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Last updated at 07:54 AM',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: AppColors.accentTeal),
                    SizedBox(width: 4),
                    Text(
                      'Optimal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Column stats: Highest 36, Lowest 6, Average 11
          Row(
            children: [
              _buildStressMetric(value: '${appState.stressHighest}', label: 'Highest'),
              const SizedBox(width: 24),
              _buildStressMetric(value: '${appState.stressLowest}', label: 'Lowest'),
              const SizedBox(width: 24),
              _buildStressMetric(value: '${appState.stressAverage}', label: 'Average'),
            ],
          ),
          const SizedBox(height: 18),

          // Sparkline bar indicator with thunderbolt icon ⚡ and percentage "0%"
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primaryContainer,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Mini vertical sparkline bars (Reference design)
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(24, (index) {
                      // Simulated physiological autonomic stress bars
                      final heights = [6, 8, 10, 7, 5, 9, 12, 16, 14, 11, 8, 7, 6, 9, 11, 13, 10, 8, 7, 6, 5, 7, 8, 6];
                      final h = heights[index].toDouble();
                      final isPeak = h > 13;

                      return Container(
                        width: 4,
                        height: h,
                        decoration: BoxDecoration(
                          color: isPeak
                              ? AppColors.primaryContainer
                              : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '0%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressMetric({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Apple-style Frosted Vitals Dashboard
  Widget _buildVitalsDashboard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Vitals", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: appState.isSyncingVitals ? null : () => appState.syncVitals(),
                child: Row(
                  children: [
                    Text(
                      appState.isSyncingVitals ? 'Syncing...' : 'Live Sync',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.sync_rounded,
                      size: 15,
                      color: AppColors.primaryContainer,
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
                child: _buildVitalTile(
                  icon: Icons.favorite_rounded,
                  value: '${appState.restingHeartRate}',
                  unit: 'bpm',
                  label: 'Resting Heart',
                  iconColor: AppColors.accentCoral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVitalTile(
                  icon: Icons.bedtime_rounded,
                  value: appState.sleepDuration,
                  unit: '',
                  label: 'Deep & REM',
                  iconColor: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVitalTile(
                  icon: Icons.directions_walk_rounded,
                  value: '${(appState.dailySteps / 1000).toStringAsFixed(1)}k',
                  unit: '',
                  label: 'Steps (84%)',
                  iconColor: AppColors.accentTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTile({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Medication tracker
  Widget _buildMedicationTracker(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medication Regimen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryContainer),
                    SizedBox(width: 4),
                    Text(
                      'Zero Conflicts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (appState.medications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No medications scheduled for today.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            ...appState.medications.map((med) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => appState.toggleMedication(med.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: med.isTaken
                                  ? AppColors.primaryContainer.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              med.isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                              color: med.isTaken ? AppColors.primaryContainer : AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: med.isTaken ? AppColors.textSecondary : AppColors.textPrimary,
                                    decoration: med.isTaken ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${med.dosage} • ${med.scheduleTime}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: med.isTaken
                                  ? AppColors.primaryContainer.withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: med.isTaken
                                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                                    : AppColors.outlineVariant,
                              ),
                            ),
                            child: Text(
                              med.isTaken ? 'Taken' : 'Mark taken',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: med.isTaken ? AppColors.primaryContainer : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Upcoming Consultation Preview
  Widget _buildUpcomingConsultation(BuildContext context) {
    if (appState.appointments.isEmpty) return const SizedBox.shrink();
    final nextAppt = appState.appointments.first;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPCOMING CONSULTATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  nextAppt.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AvatarImage(
                imageUrl: nextAppt.avatarUrl,
                initials: initialsFromName(nextAppt.doctorName),
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nextAppt.doctorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${nextAppt.specialty} • ${DateFormat('EEE, MMM d • h:mm a').format(nextAppt.dateTime)}',
                      style: AppTypography.labelSm,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: Icon(
                nextAppt.isVideoConsult ? Icons.videocam_rounded : Icons.calendar_today_rounded,
                size: 16,
              ),
              label: Text(
                nextAppt.isVideoConsult ? 'Join Video Visit' : 'Manage Consultation',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                appState.setTabIndex(3); // Visits tab
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Access Grid
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Feeling Tracker',
        'icon': Icons.mood_rounded,
        'action': () => appState.setTabIndex(1),
      },
      {
        'title': 'Symptom Triage',
        'icon': Icons.healing_rounded,
        'action': () => appState.setTabIndex(2),
      },
      {
        'title': 'Book Specialist',
        'icon': Icons.calendar_month_rounded,
        'action': () {
          appState.setTabIndex(3);
          BookAppointmentModal.show(context, appState);
        },
      },
      {
        'title': 'Lab Interpreter',
        'icon': Icons.biotech_rounded,
        'action': () => appState.setTabIndex(4),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.3,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final act = actions[index];
            return Material(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: act['action'] as VoidCallback,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(act['icon'] as IconData, color: AppColors.primaryContainer, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act['title'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Semi-circular Arc Gauge Painter (Reference: "78 / 100 Good balance")
class _BalanceArcGaugePainter extends CustomPainter {
  final int score;

  _BalanceArcGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width * 0.42;

    final bgPaint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    final sweep = math.pi * (score / 100.0).clamp(0.05, 1.0);
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF818CF8),
          AppColors.primaryContainer,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, sweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _BalanceArcGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
