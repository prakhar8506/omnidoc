import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_frame.dart';

class ActivityRings extends StatefulWidget {
  const ActivityRings({
    super.key,
    required this.recovery,
    required this.sleepHours,
    required this.strain,
    this.strainTarget = 21,
    this.loading = false,
    this.error,
    this.size = 220,
  });

  /// 0–100 when a recovery score exists.
  final double? recovery;
  final double? sleepHours;
  final double? strain;
  final double strainTarget;
  final bool loading;
  final String? error;
  final double size;

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (!widget.loading && widget.error == null) _controller.forward();
  }

  @override
  void didUpdateWidget(ActivityRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recovery != oldWidget.recovery || widget.sleepHours != oldWidget.sleepHours || widget.strain != oldWidget.strain) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recovery = widget.recovery;
    final label = recovery == null
        ? 'Recovery rings. No recovery score yet.'
        : 'Recovery ${recovery.round()}. Sleep ${widget.sleepHours == null ? 'missing' : '${widget.sleepHours!.toStringAsFixed(1)} hours'}. Strain ${widget.strain == null ? 'missing' : widget.strain!.toStringAsFixed(1)}.';
    return ChartFrame(
      semanticsLabel: label,
      loading: widget.loading,
      error: widget.error,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_controller.value);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _RingsPainter(
                    recovery: _stagger(t, 0) * ((recovery ?? 0) / 100),
                    sleep: _stagger(t, 1) * (((widget.sleepHours ?? 0) / 8).clamp(0, 1)),
                    strain: _stagger(t, 2) * (((widget.strain ?? 0) / widget.strainTarget).clamp(0, 1)),
                    drawRecovery: recovery != null,
                    drawSleep: widget.sleepHours != null,
                    drawStrain: widget.strain != null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recovery == null ? '—' : '${recovery.round()}',
                          style: TextStyle(
                            fontSize: widget.size * 0.18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -2,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1,
                          ),
                        ),
                        Text(
                          'RECOVERY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legend(context, ChartColors.violet, 'Recovery', recovery == null ? '—' : '${recovery.round()}%'),
                  _legend(context, ChartColors.sky, 'Sleep', widget.sleepHours == null ? '—' : _sleepLabel(widget.sleepHours!)),
                  _legend(context, ChartColors.coral, 'Strain', widget.strain == null ? '—' : widget.strain!.toStringAsFixed(1)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  double _stagger(double t, int index) => ((t * 900 - index * 80) / 900).clamp(0.0, 1.0);

  String _sleepLabel(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  Widget _legend(BuildContext context, Color dot, String name, String value) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.6)))),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.recovery,
    required this.sleep,
    required this.strain,
    required this.drawRecovery,
    required this.drawSleep,
    required this.drawStrain,
  });

  final double recovery;
  final double sleep;
  final double strain;
  final bool drawRecovery;
  final bool drawSleep;
  final bool drawStrain;

  static final Paint _track = strokePaint(ChartColors.track, 18);
  Size? _cachedSize;
  final List<Paint> _fills = [];

  void _ensure(Size size) {
    if (_cachedSize == size && _fills.length == 3) return;
    _cachedSize = size;
    final rect = Offset.zero & size;
    final width = 18 * size.width / 260;
    _fills
      ..clear()
      ..add(gradientStroke(rect, const [ChartColors.pink, ChartColors.violet], width))
      ..add(gradientStroke(rect, const [ChartColors.mint, ChartColors.sky], width))
      ..add(gradientStroke(rect, const [ChartColors.amber, ChartColors.coral], width));
    _track.strokeWidth = width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensure(size);
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 260;
    void ring(int index, double radius, double progress, bool draw) {
      final r = radius * scale;
      canvas.drawCircle(center, r, _track);
      if (!draw || progress <= 0) return;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0, 1),
        false,
        _fills[index],
      );
    }

    ring(0, 112, recovery, drawRecovery);
    ring(1, 88, sleep, drawSleep);
    ring(2, 64, strain, drawStrain);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.recovery != recovery || oldDelegate.sleep != sleep || oldDelegate.strain != strain;
  }
}
