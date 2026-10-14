import 'package:flutter/material.dart';

import 'chart_frame.dart';

class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({
    super.key,
    required this.counts,
    this.loading = false,
    this.error,
    this.onTap,
  });

  /// 35 cells, oldest first. Null cell means that day is outside the window.
  final List<int?> counts;
  final bool loading;
  final String? error;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final logged = counts.whereType<int>().where((n) => n > 0).length;
    return ChartFrame(
      semanticsLabel: 'Check-in grid. $logged days with a log.',
      loading: loading,
      error: error,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 35,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
        ),
        itemBuilder: (context, index) {
          final count = index < counts.length ? counts[index] : 0;
          final alpha = count == null
              ? 0.04
              : count <= 0
                  ? 0.08
                  : count == 1
                      ? 0.3
                      : count == 2
                          ? 0.55
                          : 0.8;
          return Material(
            color: const Color(0xFF5B4CE6).withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: onTap == null ? null : () => onTap!(index),
            ),
          );
        },
      ),
    );
  }
}
