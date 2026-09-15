import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/data/health_event.dart';
import 'package:health_companion/core/domains/baseline_engine.dart';

void main() {
  group('BaselineEngine Tests', () {
    test('0 days of data produces no baseline', () {
      final baseline = BaselineEngine.computeBaseline('heart_rate_variability', []);
      expect(baseline.hasBaseline, isFalse);
      expect(baseline.validDaysCount, 0);
      expect(baseline.statusMessage, contains('14 days required'));
    });

    test('5 days and 13 days of data produces no baseline', () {
      final now = DateTime.now();
      final fiveDaysEvents = List.generate(5, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 65.0 + i,
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-5-$i',
          quality: 1.0,
        );
      });

      final baseline5 = BaselineEngine.computeBaseline('heart_rate_variability', fiveDaysEvents);
      expect(baseline5.hasBaseline, isFalse);
      expect(baseline5.validDaysCount, 5);
      expect(baseline5.statusMessage, contains('5 of 14 days'));

      final thirteenDaysEvents = List.generate(13, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 65.0,
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-13-$i',
          quality: 1.0,
        );
      });

      final baseline13 = BaselineEngine.computeBaseline('heart_rate_variability', thirteenDaysEvents);
      expect(baseline13.hasBaseline, isFalse);
      expect(baseline13.validDaysCount, 13);
      expect(baseline13.statusMessage, contains('13 of 14 days'));
    });

    test('14 days exact boundary establishes personal baseline', () {
      final now = DateTime.now();
      final events14 = List.generate(14, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 60.0 + (i % 5),
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-14-$i',
          quality: 1.0,
        );
      });

      final baseline = BaselineEngine.computeBaseline('heart_rate_variability', events14);
      expect(baseline.hasBaseline, isTrue);
      expect(baseline.validDaysCount, 14);
      expect(baseline.mean, isNotNull);
      expect(baseline.stdDev, isNotNull);
      expect(baseline.statusMessage, contains('established (14 days)'));
    });

    test('21 days produces mature baseline', () {
      final now = DateTime.now();
      final events21 = List.generate(21, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'resting_heart_rate',
          value: 58.0 + (i % 3),
          unit: 'bpm',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-21-$i',
          quality: 1.0,
        );
      });

      final baseline = BaselineEngine.computeBaseline('resting_heart_rate', events21);
      expect(baseline.hasBaseline, isTrue);
      expect(baseline.isMature, isTrue);
      expect(baseline.validDaysCount, 21);
      expect(baseline.statusMessage, contains('mature (21 days)'));
    });

    test('20 calendar days with only 10 valid readings produces no baseline', () {
      final now = DateTime.now();
      // 10 valid events spread across 20 days (every alternate day)
      final sparseEvents = List.generate(10, (i) {
        final d = now.subtract(Duration(days: i * 2));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 62.0,
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-sp-$i',
          quality: 1.0,
        );
      });

      final baseline = BaselineEngine.computeBaseline('heart_rate_variability', sparseEvents);
      expect(baseline.hasBaseline, isFalse);
      expect(baseline.validDaysCount, 10);
      expect(baseline.statusMessage, contains('10 of 14 days'));
    });

    test('evaluateDeviation classifies suppressed, optimal, and elevated accurately', () {
      final now = DateTime.now();
      final events = List.generate(14, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 70.0 + (i % 2 == 0 ? 1.0 : -1.0),
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-dev-$i',
          quality: 1.0,
        );
      });

      final baseline = BaselineEngine.computeBaseline('heart_rate_variability', events);
      expect(baseline.hasBaseline, isTrue);

      final suppressedDev = baseline.evaluateDeviation(50.0);
      expect(suppressedDev, MetricDeviation.suppressed);

      final optimalDev = baseline.evaluateDeviation(70.0);
      expect(optimalDev, MetricDeviation.optimal);

      final elevatedDev = baseline.evaluateDeviation(90.0);
      expect(elevatedDev, MetricDeviation.elevated);
    });
  });
}
