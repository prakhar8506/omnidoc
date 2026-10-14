import 'package:flutter/material.dart';

import 'chart_frame.dart';
import 'ghost_line.dart';

class SleepStageStrip extends StatelessWidget {
  const SleepStageStrip({
    super.key,
    required this.stages,
    this.loading = false,
    this.error,
    this.caption = 'Sleep stages',
  });

  /// Minutes per stage, in order. Empty means the watch did not send stages.
  final List<int> stages;
  final bool loading;
  final String? error;
  final String caption;

  static const _colors = [
    Color(0xFF9B5DE5),
    Color(0xFF5B4CE6),
    Color(0xFF35B8F5),
    Color(0xFF4CD6A0),
  ];

  @override
  Widget build(BuildContext context) {
    if (!loading && error == null && stages.isEmpty) return GhostLine(caption: caption);
    return ChartFrame(
      semanticsLabel: caption,
      loading: loading,
      error: error,
      child: SizedBox(
        height: 36,
        width: double.infinity,
        child: CustomPaint(painter: _StagePainter(stages, _colors)),
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.stages, this.colors);
  final List<int> stages;
  final List<Color> colors;
  static final Paint _paint = Paint()..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final total = stages.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return;
    var x = 0.0;
    for (var i = 0; i < stages.length; i++) {
      final w = size.width * (stages[i] / total);
      _paint.color = colors[i % colors.length];
      _paint.strokeWidth = 6 + (i % 3) * 6;
      canvas.drawLine(Offset(x + 2, size.height / 2), Offset(x + w - 2, size.height / 2), _paint);
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter oldDelegate) => oldDelegate.stages != stages;
}
