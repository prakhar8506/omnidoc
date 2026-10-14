import 'package:flutter/material.dart';

/// Shared empty, loading, and error shell. The child is the hero visual.
class ChartFrame extends StatelessWidget {
  const ChartFrame({
    super.key,
    required this.semanticsLabel,
    required this.child,
    this.loading = false,
    this.error,
    this.empty = false,
    this.emptyChild,
  });

  final String semanticsLabel;
  final Widget child;
  final bool loading;
  final String? error;
  final bool empty;
  final Widget? emptyChild;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    Widget body = child;
    if (loading) {
      body = const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (error != null) {
      body = Text(error!, style: TextStyle(color: ink, height: 1.3));
    } else if (empty && emptyChild != null) {
      body = emptyChild!;
    }
    return Semantics(
      label: semanticsLabel,
      child: RepaintBoundary(child: body),
    );
  }
}

class ChartColors {
  static const track = Color(0x175B4CE6);
  static const ink = Color(0xFF1B1840);
  static const muted = Color(0xFF6A6690);
  static const pink = Color(0xFFFF7AB6);
  static const violet = Color(0xFF9B5DE5);
  static const mint = Color(0xFF4CD6A0);
  static const sky = Color(0xFF35B8F5);
  static const amber = Color(0xFFFFC25C);
  static const coral = Color(0xFFFF8A5B);
  static const danger = Color(0xFFFF7A9C);
  static const iris = Color(0xFF5B4CE6);
}

Paint strokePaint(Color color, double width) {
  return Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = color;
}

Paint gradientStroke(Rect rect, List<Color> colors, double width) {
  return Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);
}
