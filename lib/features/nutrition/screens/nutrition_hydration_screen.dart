import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';
import '../../community/screens/activity_clubs_screen.dart';
import 'diet_plan_screen.dart';
import '../widgets/log_meal_sheet.dart';

class NutritionHydrationScreen extends StatelessWidget {
  final AppState appState;

  const NutritionHydrationScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final hydrationProgress =
            (appState.dailyHydrationMl / appState.targetHydrationMl).clamp(0.0, 1.0);

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
                          Text('Nutrition & Hydration', style: AppTypography.editorialSm),
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
                        // Hydration Hero Ring Card
                        _buildHydrationCard(context, hydrationProgress),
                        const SizedBox(height: 14),
                        _buildTodayMacros(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DietPlanScreen(appState: appState)),
                            ),
                            child: const Text('Diet plan'),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Informational Correlation Card (Sodium vs Blood Pressure)
                        _buildCorrelationCard(context),
                        const SizedBox(height: 22),

                        // Meals Header & Log Button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Logged Nutrition', style: AppTypography.editorialSm),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                BouncingTap(
                                  onTap: () => appState.addHydration(250),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.watchHydration.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.water_drop_rounded, color: AppColors.watchHydration, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Log water',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                BouncingTap(
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => LogMealSheet(appState: appState),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.textPrimary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Log meal',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
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
                        const SizedBox(height: 14),
                        if (appState.hydrationLogs.isNotEmpty) ...[
                          Text(
                            'Water today · ${appState.dailyHydrationMl} ml',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final sip in appState.hydrationLogs.take(8))
                                Chip(
                                  avatar: const Icon(Icons.water_drop_rounded, size: 16, color: AppColors.watchHydration),
                                  label: Text('+${sip['ml']} ml'),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (appState.loggedMeals.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'No meals logged yet. Tap Log meal to add breakfast, lunch, or dinner.',
                              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                            ),
                          )
                        else
                          ...appState.loggedMeals.map((meal) => _buildMealItem(meal)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ActivityClubsScreen(appState: appState)),
                            ),
                            icon: const Icon(Icons.groups_rounded, size: 18),
                            label: const Text('Activity clubs'),
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
      },
    );
  }

  Widget _buildTodayMacros() {
    final totals = appState.todayMacros;
    final targets = appState.nutritionTargets;
    String line(String label, double value, int goal) => '$label ${value.round()}/$goal';
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(targets.goalLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'BMI ${targets.bmi} · ${targets.bmiLabel}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(line('Calories', totals['calories']!, targets.calories)),
          Text(line('Protein', totals['protein']!, targets.protein)),
          Text(line('Carbs', totals['carbs']!, targets.carbs)),
          Text(line('Fat', totals['fat']!, targets.fat)),
        ],
      ),
    );
  }

  Widget _buildHydrationCard(BuildContext context, double progress) {
    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded, color: AppColors.watchHydration, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY HYDRATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${appState.dailyHydrationMl} / ${appState.targetHydrationMl} ml',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Circular Ring Gauge
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _HydrationRingPainter(progress: progress),
                  child: Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick-Add Hydration Buttons
          Row(
            children: [
              Expanded(
                child: BouncingTap(
                  onTap: () => appState.addHydration(250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        '+250 ml (Glass)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BouncingTap(
                  onTap: () => appState.addHydration(500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        '+500 ml (Bottle)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      color: Colors.white.withValues(alpha: 0.85),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights_rounded, color: AppColors.accentGold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INFORMATIONAL CORRELATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sodium & blood pressure notes',
                  style: AppTypography.titleMd.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  appState.bloodPressure == '—' || appState.bloodPressure.isEmpty
                      ? 'Log meals and blood pressure to track patterns over time. This is wellness journaling — not medical advice.'
                      : 'Your latest logged blood pressure is ${appState.bloodPressure}. Discuss diet patterns with your clinician; Cura does not diagnose.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meal['title'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  meal['time'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if ((meal['calories'] as num?) != null)
              Text(
                '${meal['calories']} kcal · ${((meal['protein'] as num?) ?? 0).round()}g protein · ${((meal['carbs'] as num?) ?? 0).round()}g carbs · ${((meal['fat'] as num?) ?? 0).round()}g fat',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                meal['category'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meal['insight'] as String? ?? '',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrationRingPainter extends CustomPainter {
  final double progress;

  _HydrationRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final trackPaint = Paint()
      ..color = AppColors.watchHydration.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.watchHydration
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HydrationRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
