import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_container.dart';
import '../../ai_assistant/widgets/ai_chat_sheet.dart';
import '../widgets/journal_entry_sheet.dart';
import 'mood_check_screen.dart';

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
  late final ValueNotifier<double> _progress;
  late AnimationController _pulseController;
  String _lastHapticMood = '';

  // Dial geometry shared by painter, nodes, and touch handling.
  static const double _dialRadius = 115;
  static const double _arcStart = math.pi * 0.85;
  static const double _arcSweep = math.pi * 1.3;

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
    // Seed dial from composite energy when mood not yet set; otherwise use saved mood.
    final double seed;
    if (widget.appState.selectedMood.isEmpty && widget.appState.energyScore > 0) {
      seed = (widget.appState.energyScore / 100).clamp(0.05, 0.98);
    } else {
      seed = widget.appState.moodProgress > 0 ? widget.appState.moodProgress : 0.46;
    }
    _progress = ValueNotifier<double>(seed);
    _lastHapticMood = _moodFor(seed)['title'] as String;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progress.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _moodFor(double progress) {
    Map<String, dynamic> closest = _moods.first;
    double minDiff = 999.0;
    for (final m in _moods) {
      final prog = m['progress'] as double;
      final diff = (prog - progress).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = m;
      }
    }
    return closest;
  }

  /// Converts a touch on the dial ring into progress. Updates are local-only,
  /// so dragging stays at frame rate; persistence happens on release.
  void _handleDialTouch(Offset position, Offset center) {
    final v = position - center;
    final distance = v.distance;
    if (distance < 62 || distance > 178) return;

    var angle = math.atan2(v.dy, v.dx);
    if (angle < 0) angle += 2 * math.pi;
    const wrapEnd = math.pi * 0.15;
    const gapEnd = _arcStart;
    if (angle <= wrapEnd) {
      angle += 2 * math.pi;
    } else if (angle < gapEnd) {
      // Bottom gap — snap to the nearest arc end.
      angle = (angle - wrapEnd) < (gapEnd - angle) ? wrapEnd + 2 * math.pi : gapEnd;
    }
    final p = ((angle - _arcStart) / _arcSweep).clamp(0.0, 1.0);
    _progress.value = p;

    final active = _moodFor(p)['title'] as String;
    if (active != _lastHapticMood) {
      _lastHapticMood = active;
      HapticFeedback.selectionClick();
    }
  }

  void _commitMood() {
    final active = _moodFor(_progress.value);
    widget.appState.setMood(active['title'] as String, _progress.value);
  }

  void _selectMood(Map<String, dynamic> mood) {
    _progress.value = mood['progress'] as double;
    _lastHapticMood = mood['title'] as String;
    HapticFeedback.selectionClick();
    _commitMood();
  }

  void _onNextStep() {
    final active = _moodFor(_progress.value);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 188),
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
            'Feeling tracker helps analyse your state of mind',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Energy from vitals: ${widget.appState.energyScore}/100'
              '${widget.appState.hasVitalsData ? '' : ' • sync wearable for live score'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Curved Feeling Dial — drag anywhere on the ring.
          // The mood label sits above the arc so it never overlaps the ring.
          SizedBox(
            height: 400,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(constraints.maxWidth / 2, 228);
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (d) => _handleDialTouch(d.localPosition, center),
                  onPanUpdate: (d) => _handleDialTouch(d.localPosition, center),
                  onPanEnd: (_) => _commitMood(),
                  onTapUp: (d) {
                    _handleDialTouch(d.localPosition, center);
                    _commitMood();
                  },
                  child: ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (context, progress, _) {
                      final activeMood = _moodFor(progress);
                      final activeColor = activeMood['color'] as Color;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Glowing ambient aura behind the dial
                          Positioned(
                            left: center.dx - 110,
                            top: center.dy - 140,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        activeColor.withValues(alpha: 0.18 + _pulseController.value * 0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Arc + ticks + knob
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _FeelingArcPainter(
                                progress: progress,
                                activeColor: activeColor,
                                center: center,
                                radius: _dialRadius,
                                arcStart: _arcStart,
                                arcSweep: _arcSweep,
                              ),
                            ),
                          ),

                          // Mood nodes on the arc
                          ..._moods.map((m) {
                            final prog = m['progress'] as double;
                            final angle = _arcStart + _arcSweep * prog;
                            final isSelected = m['title'] == activeMood['title'];
                            final size = isSelected ? 38.0 : 30.0;
                            return Positioned(
                              left: center.dx + _dialRadius * math.cos(angle) - size / 2,
                              top: center.dy + _dialRadius * math.sin(angle) - size / 2,
                              child: GestureDetector(
                                onTap: () => _selectMood(m),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  width: size,
                                  height: size,
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

                          // Selected mood pill, clear of the arc peak
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.25),
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
                                        color: activeColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        activeMood['icon'] as IconData,
                                        color: activeColor,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      activeMood['title'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Center action button & step count
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _onNextStep,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
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
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.appState.feelingStep} of 8 · drag the ring',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Mood Clinical Correlation Card — follows the dial live.
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (context, progress, _) {
              final activeMood = _moodFor(progress);
              final activeColor = activeMood['color'] as Color;
              return GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        activeMood['icon'] as IconData,
                        color: activeColor,
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeMood['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Linked energy ${widget.appState.energyScore}% · HR ${widget.appState.restingHeartRate > 0 ? '${widget.appState.restingHeartRate} bpm' : '—'} · Sleep ${widget.appState.sleepDuration}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Primary Actions: New Reflection & Correlate with AI
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: Text(
                    'New Reflection',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () => JournalEntrySheet.show(context, widget.appState),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    side: BorderSide(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2C3A)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    'AI Insights',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () => AiChatSheet.show(context, widget.appState),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.psychology_alt_rounded, size: 18),
              label: Text(
                widget.appState.lastMoodCheck == null
                    ? 'Mood check'
                    : 'Mood check · ${widget.appState.lastMoodCheck!['quality']}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoodCheckScreen(appState: widget.appState)),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Section 1: Serene Autonomic & Sleep Correlations
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Health Correlations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live',
                style: AppTypography.labelSm.copyWith(color: AppColors.primaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.appState.getJournalCorrelations().map((corr) {
            final icon = corr['icon'] as IconData;
            final color = corr['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1C1E2A)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                corr['title'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  corr['metric'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          corr['insight'] as String,
                          style: TextStyle(
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
            );
          }),
          const SizedBox(height: 24),

          // Section 2: Reflections Timeline
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reflections Timeline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.appState.journalEntries.length} entries',
                style: AppTypography.labelSm.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.appState.journalEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 36, color: AppColors.textTertiary),
                  SizedBox(height: 8),
                  Text('No reflections recorded yet', style: AppTypography.titleMd),
                  SizedBox(height: 4),
                  Text(
                    'Tap "+ New Reflection" above to begin your private clinical journal.',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSm,
                  ),
                ],
              ),
            )
          else
            ...widget.appState.journalEntries.map((entry) {
              final date = entry['timestamp'] as DateTime;
              final prompt = entry['prompt'] as String;
              final content = entry['content'] as String;
              final mood = entry['mood'] as String? ?? 'Calm';
              final hasAudio = entry['audioRecorded'] == true;
              final hasPhoto = entry['photoPath'] != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1E2A)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x09000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                mood,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                            if (hasAudio) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.mic_rounded, size: 12, color: Color(0xFFEF4444)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Voice Memo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${date.day}/${date.month} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          color: AppColors.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(Icons.image_rounded, size: 36, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDateStripSelector() {
    // Real dates for the current week, Monday through Sunday.
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return {'day': labels[i], 'date': d.day.toString().padLeft(2, '0')};
    });

    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2C3A) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.08 : 0.8),
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
                color: isSelected ? (dark ? Colors.white : AppColors.textPrimary) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
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
                      color: isSelected
                          ? (dark ? AppColors.textPrimary : Colors.white)
                          : ink,
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
  final Offset center;
  final double radius;
  final double arcStart;
  final double arcSweep;

  _FeelingArcPainter({
    required this.progress,
    required this.activeColor,
    required this.center,
    required this.radius,
    required this.arcStart,
    required this.arcSweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Outer subtle tick marks radiating from arc
    final tickPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 28; i++) {
      final t = i / 28;
      final angle = arcStart + arcSweep * t;
      final r1 = radius + 8;
      final r2 = radius + (i % 4 == 0 ? 20 : 14);

      final p1 = Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle));
      final p2 = Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Arc Track Background
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, arcStart, arcSweep, false, trackPaint);

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

    final sweep = arcSweep * progress.clamp(0.02, 1.0);
    canvas.drawArc(rect, arcStart, sweep, false, activePaint);

    // Knob on arc
    final knobAngle = arcStart + sweep;
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
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.center != center;
  }
}
