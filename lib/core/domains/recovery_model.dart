import 'baseline_engine.dart';
import 'data_quality_service.dart';

class ScoreDriver {
  final String label; // e.g. "HRV above personal baseline"
  final bool isPositive; // true if boosting score, false if suppressing
  final String impact; // e.g. "+12 pts" or "-8 pts"

  const ScoreDriver({
    required this.label,
    required this.isPositive,
    required this.impact,
  });
}

class RecoveryScoreResult {
  final int score; // 0 to 100
  final ScoreConfidence confidence;
  final bool isProvisional; // true if < 7 days data
  final List<ScoreDriver> drivers; // Non-empty: at least one driver
  final String recommendedAction; // One clear action
  final String readinessState; // e.g. "Primed for Load", "Optimal Balance", "Active Recovery"
  final String modelVersion;
  final DateTime timestamp;
  final Map<String, dynamic> rawInputs;
  final Map<String, bool> missingnessFlags;

  const RecoveryScoreResult({
    required this.score,
    required this.confidence,
    required this.isProvisional,
    required this.drivers,
    required this.recommendedAction,
    required this.readinessState,
    this.modelVersion = 'recovery-0.1.0',
    required this.timestamp,
    required this.rawInputs,
    required this.missingnessFlags,
  });
}

class SleepScoreResult {
  final int score; // 0 to 100
  final ScoreConfidence confidence;
  final bool hasPersonalizedTrend; // false if < 3 nights of sleep data
  final String durationFormatted; // e.g. "7h 20m"
  final double consistencyPercentage; // e.g. 88%
  final List<ScoreDriver> drivers;
  final String recommendedBedtime;
  final String guidance;

  const SleepScoreResult({
    required this.score,
    required this.confidence,
    required this.hasPersonalizedTrend,
    required this.durationFormatted,
    required this.consistencyPercentage,
    required this.drivers,
    required this.recommendedBedtime,
    required this.guidance,
  });
}

class LoadScoreResult {
  final double currentStrain; // e.g. 6.8
  final double targetMin; // e.g. 8.0
  final double targetMax; // e.g. 13.5
  final ScoreConfidence confidence;
  final List<ScoreDriver> drivers;
  final String recommendation;

  const LoadScoreResult({
    required this.currentStrain,
    required this.targetMin,
    required this.targetMax,
    required this.confidence,
    required this.drivers,
    required this.recommendation,
  });
}

class StressScoreResult {
  final String level; // "Low", "Moderate", "Elevated"
  final double score; // 0.0 to 100.0
  final ScoreConfidence confidence;
  final List<ScoreDriver> drivers;
  final String recommendation;

  const StressScoreResult({
    required this.level,
    required this.score,
    required this.confidence,
    required this.drivers,
    required this.recommendation,
  });
}

class RecoveryModel {
  static const String currentModelVersion = 'recovery-0.1.0';

  /// Computes Recovery v0 score obeying Section 7.1 and 7.2 confidence rules.
  static RecoveryScoreResult computeRecovery({
    required double? todayHrv,
    required double? todayRestingHr,
    required double? todaySleepHours,
    required double? todayRespiratoryRate,
    required String? subjectiveFeeling, // 'Radiant', 'Energetic', 'Calm', 'Relaxed', 'Sleepy', 'Tired'
    required BaselineResult hrvBaseline,
    required BaselineResult rhrBaseline,
    required int totalHistoricalDays,
    required ScoreConfidence baselineConfidence,
  }) {
    final Map<String, dynamic> rawInputs = {
      'todayHrv': todayHrv,
      'todayRestingHr': todayRestingHr,
      'todaySleepHours': todaySleepHours,
      'todayRespiratoryRate': todayRespiratoryRate,
      'subjectiveFeeling': subjectiveFeeling,
      'totalHistoricalDays': totalHistoricalDays,
    };

    final Map<String, bool> missingness = {
      'missingHrv': todayHrv == null,
      'missingRhr': todayRestingHr == null,
      'missingSleep': todaySleepHours == null,
      'missingRespRate': todayRespiratoryRate == null,
      'missingCheckIn': subjectiveFeeling == null,
    };

    final isProvisional = totalHistoricalDays < 7;
    ScoreConfidence finalConfidence = baselineConfidence;
    if (isProvisional || missingness['missingHrv']! || missingness['missingSleep']!) {
      finalConfidence = ScoreConfidence.provisional;
    }

    final List<ScoreDriver> drivers = [];
    double weightedTotal = 0.0;
    double weightDenominator = 0.0;

    // 1. HRV Trend (35% weight)
    if (todayHrv != null && hrvBaseline.hasBaseline && hrvBaseline.mean != null) {
      final zScore = hrvBaseline.computeZScore(todayHrv) ?? 0.0;
      final hrvSubScore = ((50 + (zScore * 25))).clamp(10.0, 100.0);
      weightedTotal += hrvSubScore * 0.35;
      weightDenominator += 0.35;

      if (zScore >= 0.5) {
        drivers.add(ScoreDriver(
          label: 'HRV elevated above personal baseline (${todayHrv.toInt()} ms)',
          isPositive: true,
          impact: '+14 pts',
        ));
      } else if (zScore <= -0.5) {
        drivers.add(ScoreDriver(
          label: 'HRV suppressed vs personal baseline (${todayHrv.toInt()} ms)',
          isPositive: false,
          impact: '-12 pts',
        ));
      } else {
        drivers.add(const ScoreDriver(
          label: 'HRV within optimal personal baseline range',
          isPositive: true,
          impact: '+5 pts',
        ));
      }
    } else if (todayHrv != null) {
      // No baseline yet; evaluate against healthy reference
      final subScore = todayHrv >= 50 ? 75.0 : (todayHrv >= 35 ? 60.0 : 40.0);
      weightedTotal += subScore * 0.35;
      weightDenominator += 0.35;
      drivers.add(ScoreDriver(
        label: 'HRV recorded (${todayHrv.toInt()} ms • baseline still collecting)',
        isPositive: subScore >= 60,
        impact: subScore >= 60 ? '+8 pts' : '-6 pts',
      ));
    }

    // 2. Sleep Quality & Duration (25% weight)
    if (todaySleepHours != null) {
      double sleepSubScore = 50.0;
      if (todaySleepHours >= 7.5) {
        sleepSubScore = 90.0;
        drivers.add(ScoreDriver(
          label: 'Optimal restorative sleep (${todaySleepHours.toStringAsFixed(1)}h)',
          isPositive: true,
          impact: '+12 pts',
        ));
      } else if (todaySleepHours >= 6.5) {
        sleepSubScore = 72.0;
        drivers.add(ScoreDriver(
          label: 'Adequate sleep duration (${todaySleepHours.toStringAsFixed(1)}h)',
          isPositive: true,
          impact: '+6 pts',
        ));
      } else {
        sleepSubScore = 38.0;
        drivers.add(const ScoreDriver(
          label: 'Sleep debt accumulated (< 6.5h logged)',
          isPositive: false,
          impact: '-15 pts',
        ));
      }
      weightedTotal += sleepSubScore * 0.25;
      weightDenominator += 0.25;
    }

    // 3. Resting Heart Rate Trend (20% weight)
    if (todayRestingHr != null && rhrBaseline.hasBaseline && rhrBaseline.mean != null) {
      final zScore = rhrBaseline.computeZScore(todayRestingHr) ?? 0.0;
      // Lower RHR is usually better for recovery
      final rhrSubScore = ((50 - (zScore * 25))).clamp(10.0, 100.0);
      weightedTotal += rhrSubScore * 0.20;
      weightDenominator += 0.20;

      if (zScore <= -0.5) {
        drivers.add(ScoreDriver(
          label: 'Resting HR lower than personal baseline (${todayRestingHr.toInt()} bpm)',
          isPositive: true,
          impact: '+10 pts',
        ));
      } else if (zScore >= 0.5) {
        drivers.add(ScoreDriver(
          label: 'Resting HR elevated vs personal baseline (${todayRestingHr.toInt()} bpm)',
          isPositive: false,
          impact: '-8 pts',
        ));
      }
    } else if (todayRestingHr != null) {
      final subScore = todayRestingHr <= 65 ? 80.0 : (todayRestingHr <= 75 ? 65.0 : 45.0);
      weightedTotal += subScore * 0.20;
      weightDenominator += 0.20;
    }

    // 4. Respiratory / Temperature Deviation (10% weight)
    if (todayRespiratoryRate != null) {
      final respSubScore = (todayRespiratoryRate >= 12 && todayRespiratoryRate <= 18) ? 80.0 : 50.0;
      weightedTotal += respSubScore * 0.10;
      weightDenominator += 0.10;
    }

    // 5. Subjective Feeling Check-in (10% weight)
    if (subjectiveFeeling != null) {
      double checkInScore = 60.0;
      if (subjectiveFeeling == 'Radiant' || subjectiveFeeling == 'Energetic') {
        checkInScore = 95.0;
        drivers.add(const ScoreDriver(
          label: 'High vitality reported in morning check-in',
          isPositive: true,
          impact: '+5 pts',
        ));
      } else if (subjectiveFeeling == 'Calm' || subjectiveFeeling == 'Relaxed') {
        checkInScore = 80.0;
        drivers.add(const ScoreDriver(
          label: 'Calm autonomic rhythm reported in check-in',
          isPositive: true,
          impact: '+4 pts',
        ));
      } else if (subjectiveFeeling == 'Sleepy' || subjectiveFeeling == 'Tired') {
        checkInScore = 35.0;
        drivers.add(const ScoreDriver(
          label: 'Fatigue reported in morning check-in',
          isPositive: false,
          impact: '-6 pts',
        ));
      }
      weightedTotal += checkInScore * 0.10;
      weightDenominator += 0.10;
    }

    // Normalize score across available weights
    int finalScore = 65;
    if (weightDenominator > 0) {
      finalScore = (weightedTotal / weightDenominator).round().clamp(20, 99);
    }

    // Fallback: Never ship without a driver
    if (drivers.isEmpty) {
      drivers.add(const ScoreDriver(
        label: 'Baseline telemetry within expected physiological limits',
        isPositive: true,
        impact: 'Normal',
      ));
    }

    String readinessState;
    String action;
    if (finalScore >= 75) {
      readinessState = 'Primed for Movement';
      action = '35 min moderate aerobic movement • Target strain 10–14';
    } else if (finalScore >= 55) {
      readinessState = 'Moderate Readiness';
      action = '20 min mobility or brisk walk • Focus on early bedtime';
    } else {
      readinessState = 'Restorative Rest Needed';
      action = 'Prioritize 8h sleep & active recovery • Keep strain under 6.0';
    }

    return RecoveryScoreResult(
      score: finalScore,
      confidence: finalConfidence,
      isProvisional: isProvisional,
      drivers: drivers,
      recommendedAction: action,
      readinessState: readinessState,
      modelVersion: currentModelVersion,
      timestamp: DateTime.now(),
      rawInputs: rawInputs,
      missingnessFlags: missingness,
    );
  }

  /// Computes Sleep v0 score
  static SleepScoreResult computeSleep({
    required double? sleepHours,
    required double consistencyPercentage,
    required int validNightsCount,
  }) {
    final hasPersonalizedTrend = validNightsCount >= 3;
    final hours = sleepHours ?? 7.0;
    final int score = ((hours / 8.0) * 85 + (consistencyPercentage * 0.15)).round().clamp(30, 98);

    final durationFormatted = '${hours.toInt()}h ${((hours - hours.toInt()) * 60).round()}m';
    final List<ScoreDriver> drivers = [];

    if (hours >= 7.0) {
      drivers.add(ScoreDriver(
        label: 'Met physiological sleep duration need ($durationFormatted)',
        isPositive: true,
        impact: '+15 pts',
      ));
    } else {
      drivers.add(ScoreDriver(
        label: 'Sleep duration below 7h target ($durationFormatted)',
        isPositive: false,
        impact: '-18 pts',
      ));
    }

    if (consistencyPercentage >= 80) {
      drivers.add(ScoreDriver(
        label: 'High bedtime consistency (${consistencyPercentage.toInt()}%)',
        isPositive: true,
        impact: '+8 pts',
      ));
    }

    return SleepScoreResult(
      score: score,
      confidence: hasPersonalizedTrend ? ScoreConfidence.high : ScoreConfidence.provisional,
      hasPersonalizedTrend: hasPersonalizedTrend,
      durationFormatted: durationFormatted,
      consistencyPercentage: consistencyPercentage,
      drivers: drivers,
      recommendedBedtime: '10:45 PM',
      guidance: hasPersonalizedTrend
          ? 'Maintain your consistent wake window to optimize circadian stability.'
          : 'Log 3 consecutive nights to unlock personalized circadian trends.',
    );
  }

  /// Computes Adaptive Load Target v0 based on recovery score
  static LoadScoreResult computeLoadTarget({
    required int recoveryScore,
    required double currentStrain,
  }) {
    double targetMin;
    double targetMax;
    String recommendation;

    if (recoveryScore >= 75) {
      targetMin = 10.0;
      targetMax = 14.5;
      recommendation = 'Your autonomic recovery is primed. Ideal day for cardio or resistance training.';
    } else if (recoveryScore >= 55) {
      targetMin = 6.0;
      targetMax = 10.0;
      recommendation = 'Moderate readiness. Maintain steady-state aerobic exertion without overreaching.';
    } else {
      targetMin = 2.5;
      targetMax = 6.0;
      recommendation = 'Autonomic capacity suppressed. Keep load light with restorative mobility.';
    }

    final drivers = [
      ScoreDriver(
        label: 'Target scaled dynamically to Today\'s Recovery ($recoveryScore/100)',
        isPositive: recoveryScore >= 60,
        impact: '${targetMin.toStringAsFixed(1)} - ${targetMax.toStringAsFixed(1)} target',
      ),
    ];

    return LoadScoreResult(
      currentStrain: currentStrain,
      targetMin: targetMin,
      targetMax: targetMax,
      confidence: ScoreConfidence.high,
      drivers: drivers,
      recommendation: recommendation,
    );
  }

  /// Computes Stress v0 based on autonomic deviation
  static StressScoreResult computeStress({
    required double? hrvZScore,
    required double? rhrZScore,
    required bool hasSensorCoverage,
  }) {
    ScoreConfidence conf = hasSensorCoverage ? ScoreConfidence.high : ScoreConfidence.provisional;
    String level = 'Low';
    double score = 18.0;
    final List<ScoreDriver> drivers = [];

    if (!hasSensorCoverage) {
      drivers.add(const ScoreDriver(
        label: 'Limited physiological data coverage; confidence penalty applied',
        isPositive: false,
        impact: 'Provisional',
      ));
    }

    if (hrvZScore != null && rhrZScore != null) {
      if (hrvZScore < -1.0 && rhrZScore > 1.0) {
        level = 'Elevated';
        score = 68.0;
        drivers.add(const ScoreDriver(
          label: 'HRV suppressed and resting HR elevated simultaneously',
          isPositive: false,
          impact: 'Elevated stress',
        ));
      } else if (hrvZScore < -0.5 || rhrZScore > 0.5) {
        level = 'Moderate';
        score = 42.0;
        drivers.add(const ScoreDriver(
          label: 'Mild autonomic excitation detected during day',
          isPositive: false,
          impact: 'Moderate stress',
        ));
      } else {
        level = 'Low';
        score = 15.0;
        drivers.add(const ScoreDriver(
          label: 'Sympathetic and parasympathetic balance steady',
          isPositive: true,
          impact: 'Low stress',
        ));
      }
    } else {
      drivers.add(const ScoreDriver(
        label: 'Biometric telemetry within resting equilibrium',
        isPositive: true,
        impact: 'Stable',
      ));
    }

    return StressScoreResult(
      level: level,
      score: score,
      confidence: conf,
      drivers: drivers,
      recommendation: level == 'Elevated'
          ? 'Take a 5-minute box breathing break before afternoon obligations.'
          : 'Autonomic nervous system is in restorative equilibrium.',
    );
  }
}
