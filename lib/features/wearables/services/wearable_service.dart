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

  /// Core types first — a single unsupported type makes the whole Health
  /// Connect sheet fail, so Cura never appears in the Health Connect app list.
  static const List<HealthDataType> coreTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.BLOOD_OXYGEN,
  ];

  static Future<bool> requestAuthorization() async {
    if (!isPlatformSupported) return false;

    try {
      await _health.configure();
    } catch (e) {
      debugPrint('[WearableService] configure: $e');
    }

    final granted = await _request(coreTypes);
    if (granted) {
      // Best-effort extra types; failure must not undo the core grant.
      try {
        await _request(requiredTypes);
      } catch (e) {
        debugPrint('[WearableService] extended auth: $e');
      }
      try {
        await _request(extraTypes);
      } catch (e) {
        debugPrint('[WearableService] extra auth: $e');
      }
    }
    return granted;
  }

  /// Types a watch may or may not share. A failed request here must not
  /// block heart rate, steps, or sleep.
  /// Covered by the Health Connect permissions already in the manifest.
  static const List<HealthDataType> extraTypes = [
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.WALKING_HEART_RATE,
  ];

  static Future<bool> _request(List<HealthDataType> types) async {
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    try {
      final hasPermissions = await _health.hasPermissions(
        types,
        permissions: permissions,
      );
      if (hasPermissions == true) return true;
      return await _health.requestAuthorization(types, permissions: permissions);
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

  /// One row per signal. Missing rows stay unavailable — nothing is estimated.
  static Future<List<WatchSignal>> fetchWatchSignals() async {
    if (!isPlatformSupported) {
      return const [
        WatchSignal(
          name: 'Wearable',
          detail: 'Health sync needs Android Health Connect or Apple Health.',
          available: false,
        ),
      ];
    }

    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 36));

    Future<List<HealthDataPoint>> read(HealthDataType type) async {
      try {
        return await _health.getHealthDataFromTypes(
          types: [type],
          startTime: start,
          endTime: now,
        );
      } catch (e) {
        debugPrint('[WearableService] signal ${type.name}: $e');
        return const [];
      }
    }

    String missing(String what) =>
        'Your wearable did not provide $what, or Cura could not fetch it from your watch or tracker.';

    final out = <WatchSignal>[];

    void addDuration(String name, List<HealthDataPoint> points) {
      var minutes = 0;
      for (final point in points) {
        final span = point.dateTo.difference(point.dateFrom).inMinutes;
        if (span > 0) minutes += span;
      }
      if (minutes <= 0) {
        out.add(WatchSignal(name: name, detail: missing(name.toLowerCase()), available: false));
        return;
      }
      final hours = minutes ~/ 60;
      final remain = minutes % 60;
      final label = hours > 0 ? '${hours}h ${remain}m' : '$remain min';
      out.add(WatchSignal(
        name: name,
        detail: '$label recorded by your watch in the last 36 hours.',
        available: true,
      ));
    }

    void addNumber(String name, List<HealthDataPoint> points, String unit, {bool percent = false}) {
      double? last;
      for (final point in points) {
        final value = point.value;
        if (value is NumericHealthValue) {
          final n = value.numericValue.toDouble();
          if (n != 0) last = n;
        }
      }
      if (last == null) {
        out.add(WatchSignal(name: name, detail: missing(name.toLowerCase()), available: false));
        return;
      }
      final shown = percent && last <= 1 ? last * 100 : last;
      final text = shown >= 10 ? shown.toStringAsFixed(0) : shown.toStringAsFixed(1);
      out.add(WatchSignal(
        name: name,
        detail: '$text $unit from your watch.',
        available: true,
      ));
    }

    addDuration('Sleep', await read(HealthDataType.SLEEP_ASLEEP));
    addDuration('Deep sleep', await read(HealthDataType.SLEEP_DEEP));
    addDuration('REM sleep', await read(HealthDataType.SLEEP_REM));
    addDuration('Light sleep', await read(HealthDataType.SLEEP_LIGHT));
    addDuration('Awake time', await read(HealthDataType.SLEEP_AWAKE));
    addNumber('Heart rate', await read(HealthDataType.HEART_RATE), 'bpm');
    addNumber('Resting heart rate', await read(HealthDataType.RESTING_HEART_RATE), 'bpm');
    addNumber('Walking heart rate', await read(HealthDataType.WALKING_HEART_RATE), 'bpm');
    addNumber('Heart-rate variability', await read(HealthDataType.HEART_RATE_VARIABILITY_SDNN), 'ms');
    addNumber('Steps', await read(HealthDataType.STEPS), 'steps');
    addNumber('Blood oxygen', await read(HealthDataType.BLOOD_OXYGEN), '%', percent: true);
    final systolic = _lastNumber(await read(HealthDataType.BLOOD_PRESSURE_SYSTOLIC));
    final diastolic = _lastNumber(await read(HealthDataType.BLOOD_PRESSURE_DIASTOLIC));
    if (systolic == null || diastolic == null) {
      out.add(WatchSignal(name: 'Blood pressure', detail: missing('blood pressure'), available: false));
    } else {
      out.add(WatchSignal(
        name: 'Blood pressure',
        detail: '${systolic.round()}/${diastolic.round()} mmHg stored by your watch. Cura did not estimate it.',
        available: true,
      ));
    }

    final hrvOnFile = out.any((s) => s.name == 'Heart-rate variability' && s.available);
    final rhrOnFile = out.any((s) => s.name == 'Resting heart rate' && s.available);
    out.add(WatchSignal(
      name: 'Stress',
      detail: hrvOnFile && rhrOnFile
          ? 'Heart-rate variability and resting heart rate are on file. Cura does not turn them into a stress score.'
          : 'A stress view needs heart-rate variability from your watch. ${missing('that signal')}',
      available: hrvOnFile && rhrOnFile,
    ));

    final stepsOnFile = out.any((s) => s.name == 'Steps' && s.available);
    out.add(WatchSignal(
      name: 'Day strain',
      detail: stepsOnFile
          ? 'Steps are on file. Cura does not turn them into a strain score.'
          : missing('steps for a strain view'),
      available: stepsOnFile,
    ));

    out.add(const WatchSignal(
      name: 'VO2 max',
      detail: 'Health Connect does not share a VO2 max reading with Cura, so this watch cannot supply it here. Cura will not invent one.',
      available: false,
    ));
    out.add(const WatchSignal(
      name: 'Biological age',
      detail: 'Cura does not calculate a biological age. A connected watch does not provide that number, and Cura will not invent one.',
      available: false,
    ));

    return out;
  }

  static double? _lastNumber(List<HealthDataPoint> points) {
    double? last;
    for (final point in points) {
      final value = point.value;
      if (value is NumericHealthValue) {
        final n = value.numericValue.toDouble();
        if (n != 0) last = n;
      }
    }
    return last;
  }
}

class WatchSignal {
  const WatchSignal({
    required this.name,
    required this.detail,
    required this.available,
  });

  final String name;
  final String detail;
  final bool available;
}
