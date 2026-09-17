import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../../../core/consent/consent_manager.dart';
import '../../../core/data/health_event.dart';

/// Real HealthKit (iOS) / Health Connect (Android) integration.
/// Never invents vitals — empty results when unsupported or unauthorized.
class WearableService {
  static final Health _health = Health();

  static const List<HealthDataType> requiredTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  static String get platformSourceLabel {
    if (!isPlatformSupported) return 'Unavailable on this platform';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'Apple HealthKit'
        : 'Google Health Connect';
  }

  static String get platformSourceId {
    if (!isPlatformSupported) return 'none';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'healthkit'
        : 'health_connect';
  }

  static Future<bool> requestAuthorization() async {
    if (!isPlatformSupported) return false;

    try {
      final permissions =
          requiredTypes.map((_) => HealthDataAccess.READ).toList();
      final hasPermissions = await _health.hasPermissions(
        requiredTypes,
        permissions: permissions,
      );
      if (hasPermissions == true) return true;

      return await _health.requestAuthorization(
        requiredTypes,
        permissions: permissions,
      );
    } catch (e) {
      debugPrint('[WearableService] authorization error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchLatestVitals() async {
    final empty = <String, dynamic>{
      'restingHeartRate': 0,
      'hrvMs': 0,
      'bloodOxygen': 0,
      'dailySteps': 0.0,
      'sleepDuration': '',
      'bloodPressure': '',
      'source': platformSourceLabel,
      'deviceName': platformSourceLabel,
      'isRealHardware': false,
    };

    if (!isPlatformSupported) return empty;

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 2));
      final healthData = await _health.getHealthDataFromTypes(
        types: requiredTypes,
        startTime: start,
        endTime: now,
      );

      if (healthData.isEmpty) {
        return {...empty, 'source': platformSourceLabel};
      }

      int? restingHr;
      int? latestHr;
      int? hrv;
      int? spo2;
      int steps = 0;
      double sleepHours = 0;
      int? sys;
      int? dia;

      for (final point in healthData) {
        final val = point.value;
        if (val is! NumericHealthValue) continue;
        final n = val.numericValue.toDouble();

        switch (point.type) {
          case HealthDataType.RESTING_HEART_RATE:
            restingHr = n.round();
          case HealthDataType.HEART_RATE:
            latestHr = n.round();
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
            hrv = n.round();
          case HealthDataType.BLOOD_OXYGEN:
            spo2 = n <= 1 ? (n * 100).round() : n.round();
          case HealthDataType.STEPS:
            steps += n.round();
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
          case HealthDataType.SLEEP_LIGHT:
            final mins = point.dateTo.difference(point.dateFrom).inMinutes;
            sleepHours += mins / 60.0;
          case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
            sys = n.round();
          case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
            dia = n.round();
          default:
            break;
        }
      }

      String sleepLabel = '';
      if (sleepHours > 0) {
        final h = sleepHours.floor();
        final m = ((sleepHours - h) * 60).round();
        sleepLabel = '${h}h ${m}m';
      }

      return {
        'restingHeartRate': restingHr ?? latestHr ?? 0,
        'hrvMs': hrv ?? 0,
        'bloodOxygen': spo2 ?? 0,
        'dailySteps': steps.toDouble(),
        'sleepDuration': sleepLabel,
        'bloodPressure': (sys != null && dia != null) ? '$sys/$dia' : '',
        'source': platformSourceLabel,
        'deviceName': platformSourceLabel,
        'isRealHardware': true,
      };
    } catch (e) {
      debugPrint('[WearableService] fetchLatestVitals error: $e');
      return empty;
    }
  }

  /// Builds canonical [HealthEvent]s from platform health data. Returns [] if none.
  static Future<List<HealthEvent>> ingestEvents({
    required ConsentManager consentManager,
  }) async {
    if (!isPlatformSupported) return [];

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 14));
      final healthData = await _health.getHealthDataFromTypes(
        types: requiredTypes,
        startTime: start,
        endTime: now,
      );

      final events = <HealthEvent>[];
      final source = platformSourceId;

      for (final point in healthData) {
        final val = point.value;
        if (val is! NumericHealthValue) continue;
        final n = val.numericValue.toDouble();
        final id =
            '${point.type.name}-${point.dateFrom.millisecondsSinceEpoch}-${point.dateTo.millisecondsSinceEpoch}';

        String? metric;
        double value = n;
        String unit = 'count';

        switch (point.type) {
          case HealthDataType.RESTING_HEART_RATE:
            if (!consentManager.isCategoryEnabled(PermissionCategory.heartRate)) {
              continue;
            }
            metric = 'resting_heart_rate';
            unit = 'bpm';
          case HealthDataType.HEART_RATE:
            if (!consentManager.isCategoryEnabled(PermissionCategory.heartRate)) {
              continue;
            }
            metric = 'heart_rate';
            unit = 'bpm';
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
            if (!consentManager.isCategoryEnabled(PermissionCategory.hrv)) {
              continue;
            }
            metric = 'heart_rate_variability';
            unit = 'ms';
          case HealthDataType.STEPS:
            if (!consentManager.isCategoryEnabled(PermissionCategory.steps)) {
              continue;
            }
            metric = 'daily_steps';
            unit = 'steps';
          case HealthDataType.BLOOD_OXYGEN:
            if (!consentManager
                .isCategoryEnabled(PermissionCategory.bloodOxygen)) {
              continue;
            }
            metric = 'blood_oxygen';
            value = n <= 1 ? n * 100 : n;
            unit = '%';
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
          case HealthDataType.SLEEP_LIGHT:
            if (!consentManager.isCategoryEnabled(PermissionCategory.sleep)) {
              continue;
            }
            metric = 'sleep_duration';
            value = point.dateTo.difference(point.dateFrom).inMinutes / 60.0;
            unit = 'hours';
          default:
            continue;
        }

        events.add(HealthEvent(
          metric: metric,
          value: value,
          unit: unit,
          start: point.dateFrom,
          end: point.dateTo,
          source: source,
          sourceRecordId: id,
          quality: 1.0,
        ));
      }

      return events;
    } catch (e) {
      debugPrint('[WearableService] ingestEvents error: $e');
      return [];
    }
  }
}
