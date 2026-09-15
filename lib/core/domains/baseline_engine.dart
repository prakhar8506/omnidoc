import 'dart:math' as math;
import '../data/health_event.dart';

enum MetricDeviation {
  insufficientData,
  suppressed,
  optimal,
  elevated,
}

class BaselineResult {
  final String metric;
  final int validDaysCount;
  final bool hasBaseline; // true iff validDaysCount >= 14
  final bool isMature; // true iff validDaysCount >= 21
  final double? mean;
  final double? stdDev;
  final String statusMessage;
  final int daysRemaining;

  const BaselineResult({
    required this.metric,
    required this.validDaysCount,
    required this.hasBaseline,
    required this.isMature,
    this.mean,
    this.stdDev,
    required this.statusMessage,
    required this.daysRemaining,
  });

  MetricDeviation evaluateDeviation(double todayValue) {
    if (!hasBaseline || mean == null || stdDev == null || stdDev == 0) {
      return MetricDeviation.insufficientData;
    }
    final zScore = (todayValue - mean!) / stdDev!;
    if (zScore < -1.0) {
      return MetricDeviation.suppressed;
    } else if (zScore > 1.0) {
      return MetricDeviation.elevated;
    } else {
      return MetricDeviation.optimal;
    }
  }

  double? computeZScore(double todayValue) {
    if (!hasBaseline || mean == null || stdDev == null || stdDev == 0) {
      return null;
    }
    return (todayValue - mean!) / stdDev!;
  }
}

class BaselineEngine {
  static const int minDaysThreshold = 14;
  static const int matureDaysThreshold = 21;

  /// Calculates baseline for a metric given a historical list of events.
  /// Deduplicates multiple events per calendar day into a single daily average.
  static BaselineResult computeBaseline(String metric, List<HealthEvent> events) {
    final metricEvents = events.where((e) => e.metric == metric).toList();

    // Group by unique calendar day (yyyy-MM-dd)
    final Map<String, List<double>> dailyValues = {};
    for (final event in metricEvents) {
      final dayKey = '${event.start.year}-${event.start.month.toString().padLeft(2, '0')}-${event.start.day.toString().padLeft(2, '0')}';
      dailyValues.putIfAbsent(dayKey, () => []).add(event.value);
    }

    final int validDaysCount = dailyValues.length;
    final int daysRemaining = math.max(0, minDaysThreshold - validDaysCount);

    if (validDaysCount < minDaysThreshold) {
      return BaselineResult(
        metric: metric,
        validDaysCount: validDaysCount,
        hasBaseline: false,
        isMature: false,
        mean: null,
        stdDev: null,
        daysRemaining: daysRemaining,
        statusMessage: validDaysCount == 0
            ? 'No baseline yet • 14 days required'
            : 'Establishing baseline: $validDaysCount of $minDaysThreshold days ($daysRemaining days remaining)',
      );
    }

    // Compute daily averages
    final dailyAverages = dailyValues.values.map((vals) {
      final sum = vals.reduce((a, b) => a + b);
      return sum / vals.length;
    }).toList();

    // Compute Mean
    final mean = dailyAverages.reduce((a, b) => a + b) / dailyAverages.length;

    // Compute Standard Deviation
    final varianceSum = dailyAverages.fold<double>(
      0.0,
      (acc, val) => acc + math.pow(val - mean, 2),
    );
    final variance = varianceSum / dailyAverages.length;
    final stdDev = math.sqrt(variance);

    final isMature = validDaysCount >= matureDaysThreshold;

    return BaselineResult(
      metric: metric,
      validDaysCount: validDaysCount,
      hasBaseline: true,
      isMature: isMature,
      mean: mean,
      stdDev: stdDev > 0 ? stdDev : 1.0,
      daysRemaining: 0,
      statusMessage: isMature
          ? 'Personal baseline mature ($validDaysCount days)'
          : 'Personal baseline established ($validDaysCount days)',
    );
  }
}
