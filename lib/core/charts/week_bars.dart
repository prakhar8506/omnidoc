import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_frame.dart';
import 'ghost_line.dart';

class WeekBars extends StatelessWidget {
  const WeekBars({
    super.key,
    required this.values,
    this.labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    this.loading = false,
    this.error,
    this.caption = 'This week',
  });

  final List<double?> values;
  final List<String> labels;
  final bool loading;
  final String? error;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final present = values.whereType<double>().toList();
    if (!loading && error == null && present.isEmpty) return GhostLine(caption: caption);
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: '$caption. ${present.length} days logged.',
      loading: loading,
      error: error,
      child: SizedBox(
        height: 120,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Text(labels[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.55)));
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i] ?? 0,
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                      gradient: values[i] == null
                          ? const LinearGradient(colors: [ChartColors.track, ChartColors.track])
                          : const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [ChartColors.iris, ChartColors.violet],
                            ),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 600),
        ),
      ),
    );
  }
}
