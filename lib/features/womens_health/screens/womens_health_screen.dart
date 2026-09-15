import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';
import '../widgets/period_log_modal.dart';
import 'pregnancy_dashboard_screen.dart';

class WomensHealthScreen extends StatefulWidget {
  final AppState appState;

  const WomensHealthScreen({
    super.key,
    required this.appState,
  });

  @override
  State<WomensHealthScreen> createState() => _WomensHealthScreenState();
}

class _WomensHealthScreenState extends State<WomensHealthScreen> {
  int _selectedViewIndex = 0; // 0: Cycle Tracking, 1: Pregnancy Mode

  @override
  void initState() {
    super.initState();
    _selectedViewIndex = widget.appState.isPregnancyMode ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        if (_selectedViewIndex == 1 || widget.appState.isPregnancyMode) {
          return PregnancyDashboardScreen(appState: widget.appState);
        }

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
                          Text("Women's Health & Cycle", style: AppTypography.editorialSm),
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                            onPressed: () => _showSettingsSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Mode Switcher Tab
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedViewIndex = 0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedViewIndex == 0
                                        ? AppColors.accentRose
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Cycle Tracking',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedViewIndex == 0
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  widget.appState.setPregnancyMode(true);
                                  setState(() => _selectedViewIndex = 1);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedViewIndex == 1
                                        ? const Color(0xFFDB2777)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Pregnancy Mode',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedViewIndex == 1
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content Body
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Cycle Hero Card
                        _buildCycleHeroCard(context),
                        const SizedBox(height: 14),

                        // 2. Primary Log Period Button
                        ElevatedButton.icon(
                          onPressed: () => PeriodLogModal.show(context, widget.appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentRose,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.water_drop_rounded, size: 20),
                          label: const Text(
                            'Log Period & Flow Intensity',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 3. Feeling Journal Mood Correlation Card
                        _buildMoodCorrelationCard(context),
                        const SizedBox(height: 18),

                        // 4. Period & Flow History Timeline
                        _buildFlowHistoryCard(context),
                        const SizedBox(height: 18),

                        // 5. Symptoms Logger
                        _buildSymptomsCard(context),
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

  Widget _buildCycleHeroCard(BuildContext context) {
    final state = widget.appState;
    final cycleDay = state.cycleDay;
    final totalDays = state.averageCycleLength;
    final progress = (cycleDay / totalDays).clamp(0.05, 1.0);
    final nextPeriod = state.predictedNextPeriod;
    final daysUntilNext = nextPeriod.difference(DateTime.now()).inDays.clamp(1, 35);

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
                      const Icon(Icons.spa_rounded, color: AppColors.accentRose, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CURRENT CYCLE',
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
                    'Day $cycleDay of $totalDays',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${state.cyclePhase} • Peak Vitality',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRose,
                      ),
                    ),
                  ),
                ],
              ),
              // Dial Gauge
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _CycleDialPainter(progress: progress),
                  child: Center(
                    child: Text(
                      'Day $cycleDay',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x1A1C1A27)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CycleMetricPill(label: 'Next Period', value: 'in $daysUntilNext days'),
              const _CycleMetricPill(label: 'Fertility Window', value: 'Elevated'),
              const _CycleMetricPill(label: 'Estrogen Peak', value: 'Active'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCorrelationCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      color: Colors.white.withValues(alpha: 0.88),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.moodEnergetic.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: AppColors.moodEnergetic, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FEELING JOURNAL CORRELATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.moodEnergetic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hormonal Influence on Mood: ${widget.appState.selectedMood}',
                  style: AppTypography.titleMd,
                ),
                const SizedBox(height: 4),
                Text(
                  'You logged your feeling as "${widget.appState.selectedMood}". During the ovulatory phase, estrogen peak is clinically associated with heightened mental clarity, reduced pain sensitivity, and social vitality.',
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

  Widget _buildFlowHistoryCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Logged Period & Flow History', style: AppTypography.titleMd),
              Text(
                '${widget.appState.menstrualCycleLogs.length} logs',
                style: AppTypography.labelSm.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.appState.menstrualCycleLogs.take(4).map((log) {
            final date = log['date'] as DateTime;
            final flow = log['flow'] as String;
            final symptoms = (log['symptoms'] as List<dynamic>?)?.join(', ') ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop_rounded, size: 16, color: AppColors.accentRose),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day} ${_getMonth(date.month)} • $flow Flow',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (symptoms.isNotEmpty)
                          Text(symptoms, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      flow,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentRose),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard(BuildContext context) {
    final allSymptoms = [
      'Mild Cramps',
      'High Energy',
      'Good Mood',
      'Breast Tenderness',
      'Bloating',
      'Headache',
      'Sweet Cravings',
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Track Cycle Symptoms',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Tap to record bodily observations for this phase.',
              style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSymptoms.map((s) {
              final isSel = widget.appState.cycleSymptoms.contains(s);
              return BouncingTap(
                onTap: () => widget.appState.logCycleSymptom(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.accentRose : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSel ? AppColors.accentRose : Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Women's Health Settings", style: AppTypography.titleLg),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Menstrual Tracking Enabled', style: AppTypography.titleMd),
                subtitle: const Text('Show cycle telemetry on home and health dashboard', style: AppTypography.labelSm),
                value: widget.appState.isMenstrualTrackingEnabled,
                activeTrackColor: AppColors.accentRose,
                onChanged: (val) {
                  widget.appState.toggleMenstrualTracking(val);
                  Navigator.pop(ctx);
                },
              ),
              SwitchListTile(
                title: const Text('Pregnancy Mode', style: AppTypography.titleMd),
                subtitle: const Text('Adapt dashboard for gestational age and prenatal tracking', style: AppTypography.labelSm),
                value: widget.appState.isPregnancyMode,
                activeTrackColor: const Color(0xFFDB2777),
                onChanged: (val) {
                  widget.appState.setPregnancyMode(val);
                  setState(() => _selectedViewIndex = val ? 1 : 0);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }
}

class _CycleMetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _CycleMetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CycleDialPainter extends CustomPainter {
  final double progress;

  _CycleDialPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = const Color(0xFFF3E8FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    canvas.drawCircle(center, radius, bgPaint);

    final sweep = 2 * math.pi * progress;
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFB7185), AppColors.accentRose],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CycleDialPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
