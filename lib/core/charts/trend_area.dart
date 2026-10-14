import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_frame.dart';
import 'ghost_line.dart';

class TrendArea extends StatefulWidget {
  const TrendArea({
    super.key,
    required this.values,
    this.labels = const [],
    this.loading = false,
    this.error,
    this.caption = 'Trend',
  });

  final List<double> values;
  final List<String> labels;
  final bool loading;
  final String? error;
  final String caption;

  @override
  State<TrendArea> createState() => _TrendAreaState();
}

class _TrendAreaState extends State<TrendArea> with SingleTickerProviderStateMixin {
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
    if (!widget.loading && widget.error == null && widget.values.length < 2) {
      return GhostLine(caption: widget.caption);
    }
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: '${widget.caption}. ${widget.values.length} points.',
      loading: widget.loading,
      error: widget.error,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final shown = (widget.values.length * Curves.easeOutCubic.transform(_controller.value)).ceil().clamp(1, widget.values.length);
          final spots = [
            for (var i = 0; i < shown; i++) FlSpot(i.toDouble(), widget.values[i]),
          ];
          return SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (widget.values.length - 1).toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: widget.labels.length == widget.values.length,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 || i >= widget.labels.length) return const SizedBox.shrink();
                        return Text(widget.labels[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.55)));
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(s.y.toStringAsFixed(0), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3.5,
                    gradient: const LinearGradient(colors: [ChartColors.iris, ChartColors.pink]),
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, data) => spot.x == spots.last.x,
                      getDotPainter: (spot, percent, data, index) => FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: ChartColors.pink,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ChartColors.violet.withValues(alpha: 0.35),
                          ChartColors.violet.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
