import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  PermissionItem copyWith({
    bool? isEnabled,
    DateTime? lastSynced,
    String? dataGapWarning,
  }) {
    return PermissionItem(
      category: category,
      title: title,
      description: description,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSynced: lastSynced ?? this.lastSynced,
      dataGapWarning: dataGapWarning ?? this.dataGapWarning,
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
    final now = DateTime.now();
    _permissions[PermissionCategory.hrv] = PermissionItem(
      category: PermissionCategory.hrv,
      title: 'Heart Rate Variability (HRV)',
      description: 'Used to assess autonomic nervous system recovery and physiological stress reserves.',
      isEnabled: true,
      lastSynced: now.subtract(const Duration(minutes: 12)),
    );
    _permissions[PermissionCategory.heartRate] = PermissionItem(
      category: PermissionCategory.heartRate,
      title: 'Resting & Active Heart Rate',
      description: 'Provides resting pulse trends for recovery score calculations and cardiovascular strain tracking.',
      isEnabled: true,
      lastSynced: now.subtract(const Duration(minutes: 12)),
    );
    _permissions[PermissionCategory.sleep] = PermissionItem(
      category: PermissionCategory.sleep,
      title: 'Sleep Stages & Consistency',
      description: 'Evaluates restorative deep and REM sleep to establish your daily recovery readiness.',
      isEnabled: true,
      lastSynced: now.subtract(const Duration(hours: 4)),
    );
    _permissions[PermissionCategory.steps] = PermissionItem(
      category: PermissionCategory.steps,
      title: 'Daily Steps & Cadence',
      description: 'Measures low-intensity baseline movement to evaluate active energy and daily strain.',
      isEnabled: true,
      lastSynced: now.subtract(const Duration(minutes: 15)),
    );
    _permissions[PermissionCategory.bloodOxygen] = PermissionItem(
      category: PermissionCategory.bloodOxygen,
      title: 'Blood Oxygen Saturation (SpO₂)',
      description: 'Monitors nocturnal oxygenation stability to identify sleep disturbances.',
      isEnabled: true,
      lastSynced: now.subtract(const Duration(hours: 5)),
    );
    _permissions[PermissionCategory.respiratoryRate] = PermissionItem(
      category: PermissionCategory.respiratoryRate,
      title: 'Sleeping Respiratory Rate',
      description: 'Tracks baseline breaths per minute; deviations flag physiological strain or onset of illness.',
      isEnabled: true,
      lastSynced: now.subtract(const Duration(hours: 5)),
      dataGapWarning: null,
    );
    _permissions[PermissionCategory.location] = const PermissionItem(
      category: PermissionCategory.location,
      title: 'Workout GPS / Outdoor Location',
      description: 'Used solely during active outdoor runs or cycling to compute pace and distance. Never tracked passively.',
      isEnabled: false,
      lastSynced: null,
      dataGapWarning: 'Disabled • Outdoor pace telemetry unavailable',
    );
    _permissions[PermissionCategory.notifications] = PermissionItem(
      category: PermissionCategory.notifications,
      title: 'Recovery & Bedtime Reminders',
      description: 'Delivers calm, actionable morning recovery briefings and optimal bedtime alerts. No marketing spam.',
      isEnabled: true,
      lastSynced: now,
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
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
            _permissions[cat] = _permissions[cat]!.copyWith(
              isEnabled: isEnabled,
              lastSynced: lastSynced,
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

    _permissions[category] = _permissions[category]!.copyWith(
      isEnabled: isEnabled,
      dataGapWarning: isEnabled ? null : 'Manually disabled • Ingestion paused',
    );
    notifyListeners();
    await _persist();
  }

  Future<void> recordSync(PermissionCategory category) async {
    if (!_permissions.containsKey(category)) return;
    _permissions[category] = _permissions[category]!.copyWith(
      lastSynced: DateTime.now(),
      dataGapWarning: null,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      for (final item in _permissions.values) {
        map[item.category.name] = item.toJson();
      }
      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (e) {
      debugPrint('ConsentManager persist error: $e');
    }
  }
}
