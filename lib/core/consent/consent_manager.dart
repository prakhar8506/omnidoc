import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/secure_store.dart';

enum PermissionCategory {
  steps,
  heartRate,
  hrv,
  sleep,
  bloodOxygen,
  respiratoryRate,
  location,
  notifications,
}

class PermissionItem {
  final PermissionCategory category;
  final String title;
  final String description; // Plain-language explanation of why it is needed
  final bool isEnabled;
  final DateTime? lastSynced;
  final String? dataGapWarning;

  const PermissionItem({
    required this.category,
    required this.title,
    required this.description,
    this.isEnabled = true,
    this.lastSynced,
    this.dataGapWarning,
  });

  /// Use [clearLastSynced] / [clearDataGapWarning] to set nullable fields to null.
  PermissionItem copyWith({
    bool? isEnabled,
    DateTime? lastSynced,
    String? dataGapWarning,
    bool clearLastSynced = false,
    bool clearDataGapWarning = false,
  }) {
    return PermissionItem(
      category: category,
      title: title,
      description: description,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSynced: clearLastSynced ? null : (lastSynced ?? this.lastSynced),
      dataGapWarning:
          clearDataGapWarning ? null : (dataGapWarning ?? this.dataGapWarning),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'isEnabled': isEnabled,
        'lastSynced': lastSynced?.toIso8601String(),
        'dataGapWarning': dataGapWarning,
      };
}

class ConsentManager extends ChangeNotifier {
  static const String _storageKey = 'hc_consent_permissions';
  final Map<PermissionCategory, PermissionItem> _permissions = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<PermissionItem> get allPermissions => _permissions.values.toList();

  ConsentManager() {
    _initDefaults();
  }

  void _initDefaults() {
    // lastSynced stays null until a real wearable sync records one.
    _permissions[PermissionCategory.hrv] = const PermissionItem(
      category: PermissionCategory.hrv,
      title: 'Heart Rate Variability (HRV)',
      description:
          'Used to assess autonomic nervous system recovery and physiological stress reserves.',
      isEnabled: true,
    );
    _permissions[PermissionCategory.heartRate] = const PermissionItem(
      category: PermissionCategory.heartRate,
      title: 'Resting & Active Heart Rate',
      description:
          'Provides resting pulse trends for recovery score calculations and cardiovascular strain tracking.',
      isEnabled: true,
    );
    _permissions[PermissionCategory.sleep] = const PermissionItem(
      category: PermissionCategory.sleep,
      title: 'Sleep Stages & Consistency',
      description:
          'Evaluates restorative deep and REM sleep to establish your daily recovery readiness.',
      isEnabled: true,
    );
    _permissions[PermissionCategory.steps] = const PermissionItem(
      category: PermissionCategory.steps,
      title: 'Daily Steps & Cadence',
      description:
          'Measures low-intensity baseline movement to evaluate active energy and daily strain.',
      isEnabled: true,
    );
    _permissions[PermissionCategory.bloodOxygen] = const PermissionItem(
      category: PermissionCategory.bloodOxygen,
      title: 'Blood Oxygen Saturation (SpO₂)',
      description:
          'Monitors nocturnal oxygenation stability to identify sleep disturbances.',
      isEnabled: true,
    );
    _permissions[PermissionCategory.respiratoryRate] = const PermissionItem(
      category: PermissionCategory.respiratoryRate,
      title: 'Sleeping Respiratory Rate',
      description:
          'Tracks baseline breaths per minute; deviations flag physiological strain or onset of illness.',
      isEnabled: true,
    );
    _permissions[PermissionCategory.location] = const PermissionItem(
      category: PermissionCategory.location,
      title: 'Workout GPS / Outdoor Location',
      description:
          'Used solely during active outdoor runs or cycling to compute pace and distance. Never tracked passively.',
      isEnabled: false,
      dataGapWarning: 'Disabled • Outdoor pace telemetry unavailable',
    );
    _permissions[PermissionCategory.notifications] = const PermissionItem(
      category: PermissionCategory.notifications,
      title: 'Recovery & Bedtime Reminders',
      description:
          'Push reminders are not shipped yet. This switch does nothing until notifications are added.',
      isEnabled: false,
    );
  }

  /// Drops stored consent choices and returns to defaults. Used when an
  /// account is deleted so no consent history survives on the device.
  Future<void> reset() async {
    try {
      await SecureStore.delete(_storageKey);
    } catch (e) {
      debugPrint('ConsentManager reset error: $e');
    }
    _initDefaults();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final rawJson = await SecureStore.readString(_storageKey);
      if (rawJson != null) {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final cat = PermissionCategory.values.firstWhere(
            (c) => c.name == entry.key,
            orElse: () => PermissionCategory.steps,
          );
          if (_permissions.containsKey(cat)) {
            final data = entry.value as Map<String, dynamic>;
            final isEnabled = data['isEnabled'] as bool? ?? true;
            final lastSynced = data['lastSynced'] != null
                ? DateTime.tryParse(data['lastSynced'] as String)
                : null;
            final warning = data['dataGapWarning'] as String?;
            _permissions[cat] = PermissionItem(
              category: cat,
              title: _permissions[cat]!.title,
              description: _permissions[cat]!.description,
              isEnabled: isEnabled,
              lastSynced: lastSynced,
              dataGapWarning: warning ??
                  (isEnabled
                      ? null
                      : 'Manually disabled • Ingestion paused'),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('ConsentManager init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool isCategoryEnabled(PermissionCategory category) {
    return _permissions[category]?.isEnabled ?? false;
  }

  Future<void> toggleCategory(PermissionCategory category, bool isEnabled) async {
    if (!_permissions.containsKey(category)) return;

    final current = _permissions[category]!;
    _permissions[category] = PermissionItem(
      category: current.category,
      title: current.title,
      description: current.description,
      isEnabled: isEnabled,
      lastSynced: current.lastSynced,
      dataGapWarning:
          isEnabled ? null : 'Manually disabled • Ingestion paused',
    );
    notifyListeners();
    await _persist();
  }

  Future<void> recordSync(PermissionCategory category) async {
    if (!_permissions.containsKey(category)) return;
    final current = _permissions[category]!;
    _permissions[category] = PermissionItem(
      category: current.category,
      title: current.title,
      description: current.description,
      isEnabled: current.isEnabled,
      lastSynced: DateTime.now(),
      dataGapWarning: null,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> recordSyncForEnabledCategories() async {
    for (final cat in PermissionCategory.values) {
      if (isCategoryEnabled(cat) &&
          cat != PermissionCategory.notifications &&
          cat != PermissionCategory.location) {
        await recordSync(cat);
      }
    }
  }

  Future<void> _persist() async {
    try {
      final map = <String, dynamic>{};
      for (final item in _permissions.values) {
        map[item.category.name] = item.toJson();
      }
      await SecureStore.writeString(_storageKey, jsonEncode(map));
    } catch (e) {
      debugPrint('ConsentManager persist error: $e');
    }
  }
}
