import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_frame.dart';

class MarkerSlice {
  const MarkerSlice({required this.inRange});
  final bool inRange;
}

class MarkerDonut extends StatelessWidget {
  const MarkerDonut({
    super.key,
    required this.slices,
    this.loading = false,
    this.error,
  });

  final List<MarkerSlice> slices;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (!loading && error == null && slices.isEmpty) {
      return const ChartFrame(
        semanticsLabel: 'No markers on this report.',
        child: SizedBox(height: 130, child: Center(child: Text('—'))),
      );
    }
    final out = slices.where((s) => !s.inRange).length;
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: '$out of ${slices.length} markers out of range.',
      loading: loading,
      error: error,
      child: SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 8,
                centerSpaceRadius: 38,
                startDegreeOffset: -90,
                sections: [
                  for (final slice in slices)
                    PieChartSectionData(
                      value: 1,
                      color: slice.inRange ? ChartColors.mint : ChartColors.danger,
                      radius: 14,
                      showTitle: false,
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 700),
            ),
            FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$out/${slices.length}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: ink, height: 1)),
                  Text('OUT OF RANGE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
