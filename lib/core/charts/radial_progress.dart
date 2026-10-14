import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_frame.dart';

class RadialProgress extends StatefulWidget {
  const RadialProgress({
    super.key,
    required this.value,
    required this.label,
    this.loading = false,
    this.error,
    this.size = 72,
    this.colors = const [ChartColors.iris, ChartColors.violet],
  });

  /// 0–1, or null when the number is missing.
  final double? value;
  final String label;
  final bool loading;
  final String? error;
  final double size;
  final List<Color> colors;

  @override
  State<RadialProgress> createState() => _RadialProgressState();
}

class _RadialProgressState extends State<RadialProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.value == null ? '—' : '${(widget.value! * 100).round()}';
    return ChartFrame(
      semanticsLabel: '${widget.label} $shown',
      loading: widget.loading,
      error: widget.error,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _RadialPainter(
                progress: (widget.value ?? 0) * Curves.easeOutCubic.transform(_controller.value),
                draw: widget.value != null,
                colors: widget.colors,
              ),
              child: Center(
                child: Text(
                  shown,
                  style: TextStyle(
                    fontSize: widget.size * 0.28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  _RadialPainter({required this.progress, required this.draw, required this.colors});

  final double progress;
  final bool draw;
  final List<Color> colors;
  static final Paint _track = strokePaint(ChartColors.track, 8);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, _track..strokeWidth = 8);
    if (!draw || progress <= 0) return;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, gradientStroke(rect, colors, 8));
  }

  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.draw != draw;
}
