import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/watch_face_tile.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../appointments/widgets/book_appointment_modal.dart';
import '../../wearables/widgets/wearable_permissions_sheet.dart';
import '../../nutrition/screens/diet_plan_screen.dart';
import '../../nutrition/screens/nutrition_hydration_screen.dart';
import '../../nutrition/widgets/log_meal_sheet.dart';
import '../../premium/premium_screen.dart';
import '../../womens_health/screens/womens_health_screen.dart';
import '../../chronic_care/screens/chronic_care_screen.dart';
import '../../data_portability/screens/data_portability_screen.dart';
import '../../consent/screens/permission_center_screen.dart';
import '../../emergency/screens/emergency_safety_screen.dart';
import '../../../core/domains/data_quality_service.dart';

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recovery OS Phase 0: Header with Permission Center link
              _buildRecoveryHeader(context),
              const SizedBox(height: 16),

              // Dominant Recovery Card (Score + Confidence + Drivers + One Action Plan)
              _buildDominantRecoveryCard(context),
              const SizedBox(height: 16),

              // Tri-Stat Row: Sleep, Load, Stress
              _buildTriStatCards(context),
              const SizedBox(height: 16),

              // Action Buttons ([Log How You Feel], [Review Week])
              _buildRecoveryActionRow(context),
              const SizedBox(height: 16),
              _buildMealLog(context),
              const SizedBox(height: 20),

              // Clinical Preventive Care Banner (USPSTF / CDC Guidelines)
              _buildPreventiveCareBanner(context),

              // Ambient Hero Card: Tip + Active pill + Weather pill
              _buildAmbientWellnessCard(context),
              const SizedBox(height: 20),

              // Reference Screen 1: Today's Stress Card (Highest 36, Lowest 6, Average 11, sparkline bar graph)
              _buildTodayStressCard(context),
              const SizedBox(height: 20),

              // Apple Watch-Face Vitals Dashboard (Heart, Sleep, Steps, SpO2)
              _buildVitalsDashboard(context),
              const SizedBox(height: 20),

              // Medication Schedule with Animated Strikethrough
              _buildMedicationTracker(context),
              const SizedBox(height: 20),

              // Upcoming Consultation Preview
              _buildUpcomingConsultation(context),
              const SizedBox(height: 20),

              // Quick Access Grid to all Features
              _buildQuickActions(context),
            ],
          ),
        );
      },
    );
  }

  /// Clinical Preventive Care Banner (USPSTF / CDC Guidelines)
  Widget _buildPreventiveCareBanner(BuildContext context) {
    final activeReminders = appState.preventiveReminders.where((r) => r['isDismissed'] != true).toList();
    if (activeReminders.isEmpty) return const SizedBox.shrink();

    final reminder = activeReminders.first;
    final id = reminder['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13141F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentTeal.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: AppColors.accentTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (reminder['guideline'] as String? ?? 'USPSTF GUIDELINE').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        reminder['due'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reminder['title'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder['status'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => appState.dismissPreventiveReminder(id),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryHeader(BuildContext context) {
    final quality = appState.dataQualityService.computeDataQuality(
      appState.consentManager,
      totalHistoricalDays: appState.historicalDaysCount,
    );

    final name = appState.userName.trim();
    final ink = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF4F2FA)
        : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _greetingForNow(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.72),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PermissionCenterScreen(appState: appState),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ink.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      quality.coveragePercentage >= 75 ? Icons.shield_rounded : Icons.shield_outlined,
                      size: 14,
                      color: quality.coveragePercentage >= 75 ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${quality.coveragePercentage}% Coverage',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: ink,
            ),
          ),
        ],
      ],
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  Widget _buildMealLog(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF1C1E2A) : Colors.white;
    final ink = dark ? const Color(0xFFF4F2FA) : AppColors.textPrimary;
    final now = DateTime.now();
    bool loggedToday(String category) {
      return appState.loggedMeals.any((meal) {
        final type = (meal['category'] ?? meal['time'] ?? '').toString();
        if (type != category) return false;
        final at = DateTime.tryParse(meal['loggedAt']?.toString() ?? '');
        if (at == null) return false;
        return at.year == now.year && at.month == now.month && at.day == now.day;
      });
    }

    const slots = [
      ('Breakfast', '🥣'),
      ('Lunch', '🥗'),
      ('Dinner', '🍽️'),
      ('Snack', '🍎'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Log meals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
              ),
            ),
            TextButton.icon(
              onPressed: () => PremiumAccess.require(context, appState, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DietPlanScreen(appState: appState)),
                );
              }),
              icon: Icon(appState.hasPremium ? Icons.restaurant_menu_rounded : Icons.lock_rounded, size: 16),
              label: const Text('Meal plan'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final slot in slots) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: card.withValues(alpha: dark ? 1 : 0.86),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => LogMealSheet(
                          appState: appState,
                          initialMealType: slot.$1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        child: Column(
                          children: [
                            Text(slot.$2, style: TextStyle(fontSize: 28, height: 1)),
                            const SizedBox(height: 6),
                            Text(
                              slot.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loggedToday(slot.$1) ? 'Logged' : 'Add',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: loggedToday(slot.$1) ? AppColors.accentTeal : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _buildWaterLog(context, dark, card, ink),
      ],
    );
  }

  Widget _buildWaterLog(BuildContext context, bool dark, Color card, Color ink) {
    final now = DateTime.now();
    var mlToday = 0;
    for (final sip in appState.hydrationLogs) {
      final at = DateTime.tryParse(sip['at']?.toString() ?? '');
      if (at == null || at.year != now.year || at.month != now.month || at.day != now.day) continue;
      mlToday += (sip['ml'] as num?)?.toInt() ?? 0;
    }
    final filled = (mlToday / 250).floor().clamp(0, 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mlToday == 0 ? 'Water · tap a glass to log 250 ml' : 'Water · $mlToday ml today',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 8; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: card.withValues(alpha: dark ? 1 : 0.86),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => appState.addHydration(250),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Icon(
                          Icons.water_drop_rounded,
                          size: 18,
                          color: i < filled ? const Color(0xFF3B82F6) : ink.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Dominant Recovery Hero Card: Score + Confidence + Drivers + One Clear Action Plan
  Widget _buildDominantRecoveryCard(BuildContext context) {
    final recovery = appState.recoveryResult;
    if (recovery == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(22),
        borderRadius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primaryContainer),
                ),
                const SizedBox(width: 8),
                Text('Recovery', style: AppTypography.titleMd),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '—',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Insufficient data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect HealthKit / Health Connect or log sleep and vitals so Cura can compute a recovery score. Empty is correct until real samples exist.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      );
    }

    final isProvisional = recovery.isProvisional;
    final confLabel = recovery.confidence == ScoreConfidence.high
        ? 'High confidence'
        : (recovery.confidence == ScoreConfidence.moderate ? 'Moderate confidence' : 'Provisional');

    final confColor = recovery.confidence == ScoreConfidence.high
        ? AppColors.success
        : (recovery.confidence == ScoreConfidence.moderate ? const Color(0xFF38BDF8) : AppColors.warning);

    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Recovery Title, Readiness State, and Confidence Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primaryContainer),
              ),
              const SizedBox(width: 8),
              Text('Recovery', style: AppTypography.titleMd),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: confColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: confColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProvisional ? Icons.info_outline_rounded : Icons.check_circle_rounded,
                          size: 12,
                          color: confColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            confLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: confColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Score & Readiness Hero Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${recovery.score}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recovery.readinessState,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Provisional baseline alert notice if under 7 days
          if (isProvisional) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Provisional Score • Establishing baseline (${appState.historicalDaysCount} of 14 days recorded)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Recommended Action Box (One clear plan)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_rounded, size: 14, color: AppColors.primaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      'YOUR PLAN FOR TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryContainer.withValues(alpha: 0.9),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  recovery.recommendedAction,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Drivers Section ("What influenced today")
          Text(
            'What influenced today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: recovery.drivers.map((driver) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      driver.isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                      size: 15,
                      color: driver.isPositive ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driver.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      driver.impact,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: driver.isPositive ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Target Readiness Mode Selector ([Push] [Maintain] [Recover])
          Row(
            children: [
              Expanded(child: _buildReadinessPill('Push', recovery.score >= 75)),
              const SizedBox(width: 8),
              Expanded(child: _buildReadinessPill('Maintain', recovery.score >= 55 && recovery.score < 75)),
              const SizedBox(width: 8),
              Expanded(child: _buildReadinessPill('Recover', recovery.score < 55)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessPill(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.textPrimary : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Tri-Stat Supporting Row: Sleep, Load, and Stress Cards
  Widget _buildTriStatCards(BuildContext context) {
    final sleep = appState.sleepResult;
    final load = appState.loadResult;
    final stress = appState.stressResult;

    Widget emptyCard({
      required IconData icon,
      required Color iconColor,
      required String title,
    }) {
      return Expanded(
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(height: 8),
              Text(
                '—',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect a wearable or log data',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        if (sleep == null)
          emptyCard(
            icon: Icons.bedtime_rounded,
            iconColor: const Color(0xFF5C6BC0),
            title: 'Sleep',
          )
        else
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bedtime_rounded, size: 16, color: Color(0xFF5C6BC0)),
                  const SizedBox(height: 8),
                  Text(
                    '${sleep.score}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    sleep.durationFormatted,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sleep.drivers.isNotEmpty ? sleep.drivers.first.label : 'Sleep score',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 10),
        if (load == null)
          emptyCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF9800),
            title: 'Load',
          )
        else
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFFF9800)),
                  const SizedBox(height: 8),
                  Text(
                    load.currentStrain.toStringAsFixed(1),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    'Target: ${load.targetMin.toInt()}–${load.targetMax.toInt()}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    load.drivers.isNotEmpty ? load.drivers.first.label : 'Daily load',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 10),
        if (stress == null)
          emptyCard(
            icon: Icons.spa_rounded,
            iconColor: const Color(0xFF38BDF8),
            title: 'Stress',
          )
        else
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.spa_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      stress.level,
                      maxLines: 1,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  Text(
                    '${stress.score.toInt()}/100 index',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stress.drivers.isNotEmpty ? stress.drivers.first.label : 'Stress index',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Action buttons: Log feeling, Permission Center, Sync Wearable
  Widget _buildRecoveryActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            icon: Icon(Icons.mood_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
            label: Text('Log how you feel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            onPressed: () => appState.setTabIndex(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            icon: const Icon(Icons.sync_rounded, size: 16, color: AppColors.primaryContainer),
            label: Text('Sync Wearable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryContainer)),
            onPressed: () => WearablePermissionsSheet.show(context, appState),
          ),
        ),
      ],
    );
  }

  /// Ambient Wellness Card with Glowing Gradient Mesh, Tip pill, Active pill, Weather pill
  Widget _buildAmbientWellnessCard(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pill = dark ? const Color(0xFF2A2C3A) : Colors.white.withValues(alpha: 0.85);
    final pillInk = dark ? Theme.of(context).colorScheme.onSurface : AppColors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF1C1E2A), Color(0xFF241C28), Color(0xFF1A1C2C)]
              : const [Color(0xFFE8E5FE), Color(0xFFFDE8EF), Color(0xFFEDE0FA)],
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
                    color: pill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.9),
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
                            color: pillInk,
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
                        onTap: () async {
                          if (!appState.isWearableConnected) {
                            await WearablePermissionsSheet.show(context, appState);
                          }
                          final msg = await appState.syncVitals();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                msg.isNotEmpty
                                    ? msg
                                    : (appState.lastSyncMessage.isNotEmpty
                                        ? appState.lastSyncMessage
                                        : 'Sync complete.'),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.surfaceCardDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: pill,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_run_rounded,
                                  color: AppColors.primaryContainer,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Active',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: pillInk,
                                  ),
                                ),
                              ),
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
                          color: pill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Weather unavailable',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's energy",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appState.lastSyncedTime != null
                          ? 'Last synced ${DateFormat('h:mm a').format(appState.lastSyncedTime!)}'
                          : 'Sync a wearable to populate stress energy',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: appState.energyScore >= 60
                              ? AppColors.accentTeal
                              : AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            appState.energyScore >= 60
                                ? 'Optimal'
                                : appState.energyScore > 0
                                    ? 'Building'
                                    : 'No data',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: appState.energyScore >= 60
                                  ? AppColors.accentTeal
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Column stats from live energy / stress fields
          Row(
            children: [
              _buildStressMetric(
                context,
                value: '${appState.stressHighest > 0 ? appState.stressHighest : appState.energyScore}',
                label: 'Highest',
              ),
              const SizedBox(width: 24),
              _buildStressMetric(
                context,
                value: '${appState.stressLowest > 0 ? appState.stressLowest : (appState.energyScore * 0.35).round()}',
                label: 'Lowest',
              ),
              const SizedBox(width: 24),
              _buildStressMetric(
                context,
                value: '${appState.stressAverage > 0 ? appState.stressAverage : appState.energyScore}',
                label: 'Average',
              ),
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
                      final energy = appState.energyScore;
                      final peak = energy > 0 ? (4.0 + (energy / 100) * 18) : 4.0;
                      final wave = (index % 5 == 0) ? peak : (index % 3 == 0) ? peak * 0.55 : 4.0;
                      return Container(
                        width: 4,
                        height: wave.clamp(4.0, 22.0),
                        decoration: BoxDecoration(
                          color: energy > 0
                              ? AppColors.primaryContainer.withValues(alpha: index % 5 == 0 ? 0.85 : 0.25)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${appState.energyScore}%',
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

  Widget _buildStressMetric(BuildContext context, {required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Apple Watch-Face-Style Frosted Vitals Dashboard
  Widget _buildVitalsDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Today's Vitals & Wearables",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => WearablePermissionsSheet.show(context, appState),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.watchFaceDarkBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (appState.isWearableConnected ? AppColors.accentTeal : AppColors.primaryContainer).withValues(alpha: 0.45),
                  width: 1.1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 3.5,
                    backgroundColor: appState.isWearableConnected ? AppColors.accentTeal : AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appState.isWearableConnected
                        ? appState.wearableDeviceName
                        : (appState.isSyncingVitals ? 'Syncing...' : 'Connect Wearable'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.watch_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2x2 Watch Face Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: [
            WatchFaceTile(
              title: 'Heart Rate',
              value: '${appState.restingHeartRate}',
              unit: 'BPM',
              subtitle: 'Resting • Optimal',
              icon: Icons.favorite_rounded,
              glowColor: AppColors.watchHeartRate,
              onTap: () => appState.syncVitals(),
            ),
            WatchFaceTile(
              title: 'Sleep',
              value: appState.sleepDuration,
              subtitle: 'Deep & REM • 88% Qual',
              icon: Icons.bedtime_rounded,
              glowColor: AppColors.watchSleep,
              onTap: () => appState.syncVitals(),
            ),
            WatchFaceTile(
              title: 'Steps',
              value: '${(appState.dailySteps / 1000).toStringAsFixed(1)}k',
              unit: '/ 10k',
              subtitle: '${((appState.dailySteps / 10000) * 100).clamp(0, 999).round()}% of daily goal',
              icon: Icons.directions_walk_rounded,
              glowColor: AppColors.watchActivity,
              onTap: () => appState.syncVitals(),
            ),
            WatchFaceTile(
              title: 'SpO2',
              value: '${appState.bloodOxygen}',
              unit: '%',
              subtitle: 'Blood oxygen • Normal',
              icon: Icons.air_rounded,
              glowColor: AppColors.watchSpO2,
              onTap: () => appState.syncVitals(),
            ),
          ],
        ),
      ],
    );
  }

  /// Medication tracker with animated strikethrough and haptic feedback
  Widget _buildMedicationTracker(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Medication Regimen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              if (appState.medications.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${appState.medications.where((m) => m.isTaken).length}/${appState.medications.length} taken',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
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
                child: BouncingTap(
                  onTap: () => appState.toggleMedication(med.id),
                  child: Material(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2C3A)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
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
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: med.isTaken ? AppColors.textTertiary : AppColors.textPrimary,
                                    decoration: med.isTaken ? TextDecoration.lineThrough : TextDecoration.none,
                                    decorationColor: AppColors.textTertiary,
                                  ),
                                  child: Text(med.name),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${med.dosage} • ${med.scheduleTime}',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
            children: [
              const Expanded(
                child: Text(
                  'UPCOMING CONSULTATION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
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
                  style: TextStyle(
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
                    Text(nextAppt.doctorName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                appState.setBiologySegment(1);
                appState.setTabIndex(4);
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
        'title': 'Nutrition & Hydration',
        'icon': Icons.local_drink_rounded,
        'color': AppColors.accentTeal,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NutritionHydrationScreen(appState: appState)),
        ),
      },
      {
        'title': "Women's Health",
        'icon': Icons.favorite_border_rounded,
        'color': AppColors.accentCoral,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WomensHealthScreen(appState: appState)),
        ),
      },
      {
        'title': 'Chronic Care',
        'icon': Icons.monitor_heart_rounded,
        'color': AppColors.accentAmber,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChronicCareScreen(appState: appState)),
        ),
      },
      {
        'title': 'SOS ID',
        'icon': Icons.emergency_rounded,
        'color': const Color(0xFFEF4444),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmergencySafetyScreen(appState: appState)),
        ),
      },
      {
        'title': 'Export FHIR & PDF',
        'icon': Icons.file_download_rounded,
        'color': const Color(0xFF6366F1),
        'action': () => PremiumAccess.require(
          context,
          appState,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DataPortabilityScreen(appState: appState)),
          ),
        ),
      },
      {
        'title': 'Wearables',
        'icon': Icons.watch_rounded,
        'color': const Color(0xFFEC4899),
        'action': () => WearablePermissionsSheet.show(context, appState),
      },
      {
        'title': 'Feeling Tracker',
        'icon': Icons.mood_rounded,
        'color': AppColors.primaryContainer,
        'action': () => appState.setTabIndex(1),
      },
      {
        'title': 'Symptom Triage',
        'icon': Icons.healing_rounded,
        'color': AppColors.accentCoral,
        'action': () => appState.setTabIndex(2),
      },
      {
        'title': 'Book Specialist',
        'icon': Icons.calendar_month_rounded,
        'color': AppColors.accentTeal,
        'action': () {
          appState.setBiologySegment(1);
          appState.setTabIndex(4);
          BookAppointmentModal.show(context, appState);
        },
      },
      {
        'title': 'Lab Interpreter',
        'icon': Icons.biotech_rounded,
        'color': const Color(0xFF8B5CF6),
        'action': () => PremiumAccess.require(context, appState, () => appState.setTabIndex(4)),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access & Clinical Care',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF4F2FA)
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 76,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final act = actions[index];
            final color = (act['color'] as Color?) ?? AppColors.primaryContainer;

            return BouncingTap(
              onTap: act['action'] as VoidCallback,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                elevation: 0,
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
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(act['icon'] as IconData, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act['title'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.15,
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

