import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_container.dart';
import '../../ai_assistant/widgets/ai_chat_sheet.dart';

class JournalFeelingScreen extends StatefulWidget {
  final AppState appState;

  const JournalFeelingScreen({
    super.key,
    required this.appState,
  });

  @override
  State<JournalFeelingScreen> createState() => _JournalFeelingScreenState();
}

class _JournalFeelingScreenState extends State<JournalFeelingScreen> with SingleTickerProviderStateMixin {
  late double _currentProgress;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _moods = const [
    {
      'title': 'Sleepy',
      'icon': Icons.bedtime_rounded,
      'color': Color(0xFF818CF8),
      'progress': 0.10,
      'description': 'Rest needed, low energy reserves',
    },
    {
      'title': 'Relaxed',
      'icon': Icons.spa_rounded,
      'color': Color(0xFF34D399),
      'progress': 0.28,
      'description': 'Calm, balanced autonomic rhythm',
    },
    {
      'title': 'Calm',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFF38BDF8),
      'progress': 0.46,
      'description': 'Peaceful mind, optimal heart variability',
    },
    {
      'title': 'Energetic',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFF6E5DF6),
      'progress': 0.65,
      'description': 'High vitality, ready for physical activity',
    },
    {
      'title': 'Focused',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFFA855F7),
      'progress': 0.82,
      'description': 'Sharp cognitive flow, deep concentration',
    },
    {
      'title': 'Radiant',
      'icon': Icons.wb_sunny_rounded,
      'color': Color(0xFFFB7185),
      'progress': 0.96,
      'description': 'Peak joy and holistic wellbeing',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.appState.moodProgress;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getActiveMood() {
    Map<String, dynamic> closest = _moods.first;
    double minDiff = 999.0;
    for (final m in _moods) {
      final prog = m['progress'] as double;
      final diff = (prog - _currentProgress).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = m;
      }
    }
    return closest;
  }

  void _onNextStep() {
    final active = _getActiveMood();
    final nextStep = (widget.appState.feelingStep % 8) + 1;
    widget.appState.logFeeling(
      mood: active['title'] as String,
      step: nextStep,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged “${active['title']}” feeling • Daily balance updated to ${widget.appState.dailyBalanceScore}%'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMood = _getActiveMood();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 7-Day Horizontal Calendar Strip (Reference: Tu 03, We 04, Th 05...)
          _buildDateStripSelector(),
          const SizedBox(height: 24),

          // Editorial Headline
          Text(
            'How are you\nfeeling today?',
            textAlign: TextAlign.center,
            style: AppTypography.editorialLg.copyWith(
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feeling tracker helps to analyse your state on mind',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Interactive Curved Feeling Dial with glowing nodes
          SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing background ambient aura
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (activeMood['color'] as Color).withValues(alpha: 0.18 + _pulseController.value * 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Arc Dial Painter with Ticks
                CustomPaint(
                  size: const Size(320, 240),
                  painter: _FeelingArcPainter(
                    progress: _currentProgress,
                    activeColor: activeMood['color'] as Color,
                  ),
                ),

                // Interactive Mood Node Icons positioned on the arc
                ..._moods.map((m) {
                  final prog = m['progress'] as double;
                  // Map progress (0..1) to angle between 150 deg and 30 deg
                  final angle = math.pi * (1.0 - 0.75 * prog) + 0.35;
                  const radius = 115.0;
                  final x = radius * math.cos(angle);
                  final y = -radius * math.sin(angle) + 40;

                  final isSelected = m['title'] == activeMood['title'];

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentProgress = m['progress'] as double;
                        });
                        widget.appState.setMood(m['title'] as String, _currentProgress);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isSelected ? 38 : 30,
                        height: isSelected ? 38 : 30,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (m['color'] as Color)
                                : Colors.white.withValues(alpha: 0.9),
                            width: isSelected ? 2.5 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (m['color'] as Color).withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Icon(
                            m['icon'] as IconData,
                            size: isSelected ? 18 : 14,
                            color: isSelected ? (m['color'] as Color) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Selected Mood Center Badge (Reference: Floating pill "⚡ Energetic")
                Positioned(
                  top: 20,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (activeMood['color'] as Color).withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: (activeMood['color'] as Color).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activeMood['icon'] as IconData,
                            color: activeMood['color'] as Color,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activeMood['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Action Button & Step Count (Reference: Dark button with "->" and "4 of 8")
                Positioned(
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _onNextStep,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.appState.feelingStep} of 8',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Mood Clinical Correlation Card
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (activeMood['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    activeMood['icon'] as IconData,
                    color: activeMood['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'State: ${activeMood['title']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeMood['description'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action prompt: Discuss with AI
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: BorderSide(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                backgroundColor: Colors.white.withValues(alpha: 0.7),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                'Correlate ${activeMood['title']} state with AI Copilot',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => AiChatSheet.show(context, widget.appState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStripSelector() {
    const days = [
      {'day': 'Tu', 'date': '03'},
      {'day': 'We', 'date': '04'},
      {'day': 'Th', 'date': '05'},
      {'day': 'Fr', 'date': '06'},
      {'day': 'Sa', 'date': '07'},
      {'day': 'Su', 'date': '08'},
      {'day': 'Mo', 'date': '09'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (index) {
          final isSelected = widget.appState.selectedDateIndex == index;
          final d = days[index];

          return GestureDetector(
            onTap: () {
              widget.appState.setSelectedDateIndex(index);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    d['day']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d['date']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FeelingArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;

  _FeelingArcPainter({
    required this.progress,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 40);
    const radius = 115.0;

    // Outer subtle tick marks radiating from arc
    final tickPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 28; i++) {
      final t = i / 28;
      final angle = math.pi * (1.15 - 1.3 * t);
      const r1 = radius + 8;
      final r2 = radius + (i % 4 == 0 ? 20 : 14);

      final p1 = Offset(center.dx + r1 * math.cos(angle), center.dy - r1 * math.sin(angle));
      final p2 = Offset(center.dx + r2 * math.cos(angle), center.dy - r2 * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Arc Track Background
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi * 0.85, math.pi * 1.3, false, trackPaint);

    // Active Gradient Arc
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF818CF8),
          activeColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweep = (math.pi * 1.3) * progress.clamp(0.05, 1.0);
    canvas.drawArc(rect, math.pi * 0.85, sweep, false, activePaint);

    // Knob on arc
    final knobAngle = math.pi * 0.85 + sweep;
    final knobCenter = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );

    // Knob shadow & glowing white center
    canvas.drawCircle(
      knobCenter,
      13,
      Paint()..color = activeColor.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      knobCenter,
      10,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      knobCenter,
      5,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _FeelingArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
  }
}
