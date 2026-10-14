import 'package:flutter/material.dart';

import 'chart_frame.dart';

class GhostLine extends StatelessWidget {
  const GhostLine({super.key, this.caption = 'No reading yet'});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: caption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(painter: _GhostPainter(color: ChartColors.pink.withValues(alpha: 0.7))),
          ),
          const SizedBox(height: 6),
          Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: ink.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _GhostPainter extends CustomPainter {
  _GhostPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.26, size.height * 0.18)
      ..lineTo(size.width * 0.34, size.height * 0.82)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    const dash = 4.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = mathMin(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GhostPainter oldDelegate) => oldDelegate.color != color;
}

double mathMin(double a, double b) => a < b ? a : b;
