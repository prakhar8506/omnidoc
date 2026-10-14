import 'package:flutter/material.dart';

import 'chart_frame.dart';

class MoodOrb extends StatelessWidget {
  const MoodOrb({
    super.key,
    required this.mood,
    this.colors = const [Color(0xFFFFE3A3), Color(0xFFFF9BBF), Color(0xFF9B5DE5)],
    this.loading = false,
    this.error,
    this.size = 160,
  });

  final String? mood;
  final List<Color> colors;
  final bool loading;
  final String? error;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      semanticsLabel: mood == null ? 'No mood chosen.' : 'Mood $mood',
      loading: loading,
      error: error,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: mood == null
                  ? const [Color(0xFFE4E0F4), Color(0xFFD5D0E8), Color(0xFFC9C4DE)]
                  : colors,
              stops: const [0, 0.45, 0.85],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF8AAA).withValues(alpha: mood == null ? 0.1 : 0.55), blurRadius: 70),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              mood ?? '—',
              key: ValueKey(mood),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
