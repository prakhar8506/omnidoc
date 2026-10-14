import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_frame.dart';

class DropPictogram extends StatelessWidget {
  const DropPictogram({
    super.key,
    required this.filled,
    this.total = 8,
    this.onAdd,
    this.loading = false,
    this.error,
  });

  final int filled;
  final int total;
  final VoidCallback? onAdd;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final safeFilled = filled.clamp(0, total);
    return ChartFrame(
      semanticsLabel: '$safeFilled of $total glasses.',
      loading: loading,
      error: error,
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: GestureDetector(
                onTap: onAdd == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onAdd!();
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CustomPaint(
                    size: const Size(11, 15),
                    painter: _DropPainter(filled: i < safeFilled),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  _DropPainter({required this.filled});
  final bool filled;
  static Path? _path;

  Path _drop(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(size.width, size.height * 0.45, size.width, size.height * 0.62)
      ..arcToPoint(Offset(0, size.height * 0.62), radius: Radius.circular(size.width * 0.7), clockwise: true)
      ..quadraticBezierTo(0, size.height * 0.45, size.width / 2, 0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _path ??= _drop(const Size(11, 15));
    final path = size == const Size(11, 15) ? _path! : _drop(size);
    final paint = Paint()..color = ChartColors.sky.withValues(alpha: filled ? 1 : 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DropPainter oldDelegate) => oldDelegate.filled != filled;
}
