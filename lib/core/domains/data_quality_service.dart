import '../consent/consent_manager.dart';
import '../data/health_event.dart';

enum ScoreConfidence {
  provisional,
  moderate,
  high,
}

class DataQualityResult {
  final int coveragePercentage;
  final ScoreConfidence confidence;
  final String statusLabel;
  final String description;
  final bool isStale;
  final String? conflictWarning;
  final String? preferredSource;

  const DataQualityResult({
    required this.coveragePercentage,
    required this.confidence,
    required this.statusLabel,
    required this.description,
    required this.isStale,
    this.conflictWarning,
    this.preferredSource,
  });
}

class DataQualityService {
  /// Evaluates permission coverage and data flow freshness
  DataQualityResult computeDataQuality(
    ConsentManager consent, {
    List<HealthEvent> recentEvents = const [],
    int totalHistoricalDays = 14,
  }) {
    final permissions = consent.allPermissions;
    if (permissions.isEmpty) {
      return const DataQualityResult(
        coveragePercentage: 0,
        confidence: ScoreConfidence.provisional,
        statusLabel: 'No Permissions Granted',
        description: 'Sensor data ingestion is currently disabled. All scores are provisional.',
        isStale: true,
      );
    }

    final enabledCount = permissions.where((p) => p.isEnabled).length;
    final coveragePercentage = ((enabledCount / permissions.length) * 100).round();

    // Check freshness: was there a sync within the last 24 hours?
    final now = DateTime.now();
    bool isStale = true;
    for (final p in permissions) {
      if (p.isEnabled && p.lastSynced != null) {
        if (now.difference(p.lastSynced!).inHours < 24) {
          isStale = false;
          break;
        }
      }
    }

    // Check for source conflicts in recent readings
    String? conflictWarning;
    String? preferredSource;
    final Map<String, Set<String>> sourcesPerMetric = {};
    for (final e in recentEvents) {
      sourcesPerMetric.putIfAbsent(e.metric, () => {}).add(e.source);
    }
    for (final entry in sourcesPerMetric.entries) {
      if (entry.value.length > 1) {
        conflictWarning = 'Multi-source conflict on ${entry.key}: ${entry.value.join(", ")}';
        preferredSource = entry.value.contains('healthkit')
            ? 'Apple HealthKit'
            : entry.value.contains('health_connect')
                ? 'Google Health Connect'
                : 'Primary Wearable';
        break;
      }
    }

    ScoreConfidence confidence;
    if (totalHistoricalDays < 7 || coveragePercentage < 50 || !consent.isCategoryEnabled(PermissionCategory.hrv)) {
      confidence = ScoreConfidence.provisional;
    } else if (coveragePercentage >= 80 && !isStale) {
      confidence = ScoreConfidence.high;
    } else {
      confidence = ScoreConfidence.moderate;
    }

    String statusLabel;
    switch (confidence) {
      case ScoreConfidence.high:
        statusLabel = 'Optimal Quality • High Confidence';
        break;
      case ScoreConfidence.moderate:
        statusLabel = 'Moderate Quality • Sufficient Confidence';
        break;
      case ScoreConfidence.provisional:
        statusLabel = 'Provisional Quality • Limited Confidence';
        break;
    }

    String description = 'Active sensor coverage is $coveragePercentage%. ';
    if (totalHistoricalDays < 7) {
      description += 'Fewer than 7 days recorded; score is flagged as provisional.';
    } else if (isStale) {
      description += 'Telemetry is older than 24 hours; connect wearable to refresh.';
    } else {
      description += 'Sufficient biometric resolution for recovery modeling.';
    }

    return DataQualityResult(
      coveragePercentage: coveragePercentage,
      confidence: confidence,
      statusLabel: statusLabel,
      description: description,
      isStale: isStale,
      conflictWarning: conflictWarning,
      preferredSource: preferredSource,
    );
  }
}
