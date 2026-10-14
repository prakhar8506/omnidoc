import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_frame.dart';

class ReadinessGauge extends StatefulWidget {
  const ReadinessGauge({
    super.key,
    required this.score,
    this.caption = 'READY TO MOVE',
    this.loading = false,
    this.error,
  });

  /// 0–100, or null when readiness was not scored.
  final double? score;
  final String caption;
  final bool loading;
  final String? error;

  @override
  State<ReadinessGauge> createState() => _ReadinessGaugeState();
}

class _ReadinessGaugeState extends State<ReadinessGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final shown = widget.score == null ? '—' : '${widget.score!.round()}';
    return ChartFrame(
      semanticsLabel: 'Readiness $shown. ${widget.caption}',
      loading: widget.loading,
      error: widget.error,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 260,
            height: 150,
            child: CustomPaint(
              painter: _GaugePainter(
                progress: widget.score == null ? 0 : (widget.score! / 100) * Curves.easeOutCubic.transform(_controller.value),
                draw: widget.score != null,
              ),
              child: Align(
                alignment: const Alignment(0, 0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(shown, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: -1, color: ink, height: 1)),
                    Text(
                      widget.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: ink.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.draw});

  final double progress;
  final bool draw;
  static final Paint _track = strokePaint(ChartColors.track, 20);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 16);
    final radius = math.min(size.width / 2 - 24, size.height - 28);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi, math.pi, false, _track);
    if (!draw || progress <= 0) return;
    canvas.drawArc(rect, math.pi, math.pi * progress.clamp(0, 1), false, gradientStroke(rect, const [ChartColors.mint, ChartColors.sky], 20));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.draw != draw;
}
