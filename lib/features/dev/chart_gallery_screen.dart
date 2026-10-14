import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/charts/charts.dart';

/// Debug comparison board. Sample numbers here are the design reference, not a person's data.
class ChartGalleryScreen extends StatelessWidget {
  const ChartGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('This screen is only in debug builds.')));
    }
    return Theme(
      data: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: const Color(0xFFF4F1FB)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F1FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F1FB),
          foregroundColor: ChartColors.ink,
          elevation: 0,
          title: const Text('Chart gallery', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _card(const ActivityRings(recovery: 46, sleepHours: 7, strain: 3, strainTarget: 14, size: 240)),
            _card(const ReadinessGauge(score: 52)),
            _card(const TrendArea(values: [40, 42, 38, 55, 48, 60, 52], labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'], caption: 'Recovery')),
            _card(const WeekBars(values: [3, 5, null, 8, 4, 6, 2], caption: 'Week')),
            _card(const SleepStageStrip(stages: [20, 40, 15, 30])),
            _card(const MarkerDonut(slices: [
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: false),
              MarkerSlice(inRange: true),
            ])),
            _card(const RangeBar(value: 142, low: 70, high: 99, caption: 'Example marker')),
            _card(ConsistencyHeatmap(counts: List<int>.generate(35, (i) => i % 4))),
            _card(const DropPictogram(filled: 3)),
            _card(const MoodOrb(mood: 'Calm')),
            _card(const ZoneBar(active: 2, caption: 'Zone 3')),
            _card(const StepDots(count: 8, index: 3)),
            _card(const StressScale(value: 0.4, caption: 'Steady')),
            _card(const AvatarStack(names: ['Asha', 'Dev', 'Mina'])),
            _card(const GhostLine(caption: 'No heart-rate reading yet')),
            _card(const RadialProgress(value: 0.62, label: 'Coverage')),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: child,
    );
  }
}
