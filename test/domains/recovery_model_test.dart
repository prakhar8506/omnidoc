import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/domains/recovery_model.dart';
import 'package:health_companion/core/domains/baseline_engine.dart';
import 'package:health_companion/core/domains/data_quality_service.dart';
import 'package:health_companion/core/data/health_event.dart';

void main() {
  group('RecoveryModel Tests', () {
    test('< 7 days data marks recovery as provisional with provisional confidence', () {
      final now = DateTime.now();
      final events3Days = List.generate(3, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 65.0,
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-3-$i',
          quality: 1.0,
        );
      });

      final hrvBaseline = BaselineEngine.computeBaseline('heart_rate_variability', events3Days);
      final rhrBaseline = BaselineEngine.computeBaseline('resting_heart_rate', events3Days);

      final result = RecoveryModel.computeRecovery(
        todayHrv: 64.0,
        todayRestingHr: 60.0,
        todaySleepHours: 7.5,
        todayRespiratoryRate: 15.0,
        subjectiveFeeling: 'Energetic',
        hrvBaseline: hrvBaseline,
        rhrBaseline: rhrBaseline,
        totalHistoricalDays: 3,
        baselineConfidence: ScoreConfidence.provisional,
      );

      expect(result.isProvisional, isTrue);
      expect(result.confidence, ScoreConfidence.provisional);
      expect(result.drivers.isNotEmpty, isTrue);
      expect(result.recommendedAction.isNotEmpty, isTrue);
      expect(result.modelVersion, 'recovery-0.1.0');
    });

    test('Missing HRV or Sleep drops confidence to provisional', () {
      final now = DateTime.now();
      final events14Days = List.generate(14, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 65.0 + (i % 3),
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-14-$i',
          quality: 1.0,
        );
      });

      final hrvBaseline = BaselineEngine.computeBaseline('heart_rate_variability', events14Days);
      final rhrBaseline = BaselineEngine.computeBaseline('resting_heart_rate', events14Days);

      // Missing HRV (null) with 14 days history
      final missingHrvResult = RecoveryModel.computeRecovery(
        todayHrv: null,
        todayRestingHr: 58.0,
        todaySleepHours: 8.0,
        todayRespiratoryRate: 15.0,
        subjectiveFeeling: 'Calm',
        hrvBaseline: hrvBaseline,
        rhrBaseline: rhrBaseline,
        totalHistoricalDays: 14,
        baselineConfidence: ScoreConfidence.high,
      );
      expect(missingHrvResult.confidence, ScoreConfidence.provisional);

      // Missing Sleep (null) with 14 days history
      final missingSleepResult = RecoveryModel.computeRecovery(
        todayHrv: 68.0,
        todayRestingHr: 58.0,
        todaySleepHours: null,
        todayRespiratoryRate: 15.0,
        subjectiveFeeling: 'Calm',
        hrvBaseline: hrvBaseline,
        rhrBaseline: rhrBaseline,
        totalHistoricalDays: 14,
        baselineConfidence: ScoreConfidence.high,
      );
      expect(missingSleepResult.confidence, ScoreConfidence.provisional);
    });

    test('Output always contains at least one driver, a recommended action, and modelVersion', () {
      final now = DateTime.now();
      final events14Days = List.generate(14, (i) {
        final d = now.subtract(Duration(days: i));
        return HealthEvent(
          metric: 'heart_rate_variability',
          value: 70.0 + (i % 2),
          unit: 'ms',
          start: d,
          end: d.add(const Duration(minutes: 5)),
          source: 'healthkit',
          sourceRecordId: 'hk-14-$i',
          quality: 1.0,
        );
      });

      final hrvBaseline = BaselineEngine.computeBaseline('heart_rate_variability', events14Days);
      final rhrBaseline = BaselineEngine.computeBaseline('resting_heart_rate', events14Days);

      final result = RecoveryModel.computeRecovery(
        todayHrv: 72.0,
        todayRestingHr: 56.0,
        todaySleepHours: 8.2,
        todayRespiratoryRate: 14.5,
        subjectiveFeeling: 'Energetic',
        hrvBaseline: hrvBaseline,
        rhrBaseline: rhrBaseline,
        totalHistoricalDays: 14,
        baselineConfidence: ScoreConfidence.high,
      );

      expect(result.score, inInclusiveRange(0, 100));
      expect(result.isProvisional, isFalse);
      expect(result.confidence, ScoreConfidence.high);
      expect(result.drivers, isNotEmpty);
      for (final driver in result.drivers) {
        expect(driver.label.isNotEmpty, isTrue);
        expect(driver.impact.isNotEmpty, isTrue);
      }
      expect(result.recommendedAction.isNotEmpty, isTrue);
      expect(result.modelVersion, 'recovery-0.1.0');
    });

    test('Sleep, Load, Stress models conform to mandatory guardrails', () {
      final sleepScore = RecoveryModel.computeSleep(
        sleepHours: 7.2,
        consistencyPercentage: 88.0,
        validNightsCount: 7,
      );
      expect(sleepScore.score, inInclusiveRange(0, 100));
      expect(sleepScore.drivers, isNotEmpty);
      expect(sleepScore.guidance.isNotEmpty, isTrue);

      final loadScore = RecoveryModel.computeLoadTarget(
        recoveryScore: 78,
        currentStrain: 8.5,
      );
      expect(loadScore.targetMin, lessThanOrEqualTo(loadScore.targetMax));
      expect(loadScore.drivers, isNotEmpty);
      expect(loadScore.recommendation.isNotEmpty, isTrue);

      final stressScore = RecoveryModel.computeStress(
        hrvZScore: 0.1,
        rhrZScore: -0.2,
        hasSensorCoverage: true,
      );
      expect(stressScore.score, inInclusiveRange(0, 100));
      expect(stressScore.drivers, isNotEmpty);
      expect(stressScore.recommendation.isNotEmpty, isTrue);
    });
  });
}
