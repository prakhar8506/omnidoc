import 'package:flutter/foundation.dart';

class AnalyticsEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AnalyticsEvent({
    required this.name,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'event': name,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  @override
  String toString() => 'AnalyticsEvent($name, $metadata, $timestamp)';
}

/// Zero-PII Analytics and telemetry service.
/// Coarse metadata only; strictly filters out health values, names, and emails.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final List<AnalyticsEvent> _eventLog = [];
  final List<String> _disallowedKeys = [
    'email',
    'name',
    'password',
    'phone',
    'address',
    'hrv',
    'heart_rate',
    'weight',
    'blood_pressure',
    'photo',
    'note',
    'content'
  ];

  List<AnalyticsEvent> get eventLog => List.unmodifiable(_eventLog);

  void logEvent(String eventName, [Map<String, dynamic>? metadata]) {
    final sanitizedMetadata = <String, dynamic>{};
    if (metadata != null) {
      for (final entry in metadata.entries) {
        final keyLower = entry.key.toLowerCase();
        if (_disallowedKeys.any((disallowed) => keyLower.contains(disallowed))) {
          // Reject PII key
          continue;
        }
        // Only allow coarse types
        if (entry.value is bool || entry.value is int || entry.value is String) {
          sanitizedMetadata[entry.key] = entry.value;
        }
      }
    }

    final event = AnalyticsEvent(
      name: eventName,
      metadata: sanitizedMetadata,
    );

    _eventLog.add(event);
    if (_eventLog.length > 500) {
      _eventLog.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('[Telemetry] ${event.name}: ${event.metadata}');
    }
  }

  // Pre-defined event triggers from Section 11:
  void logScoreViewed({required String scoreType, required String confidence}) {
    logEvent('score_viewed', {
      'score_type': scoreType,
      'confidence': confidence,
    });
  }

  void logBaselineEstablished({required String metric, required int daysTaken}) {
    logEvent('baseline_established', {
      'metric': metric,
      'days_taken': daysTaken,
    });
  }

  void logPermissionToggled({required String category, required bool isEnabled}) {
    logEvent('permission_toggled', {
      'category': category,
      'is_enabled': isEnabled,
    });
  }

  void logSyncFailure({required String source, required String reason}) {
    logEvent('sync_failure', {
      'source': source,
      'reason': reason,
    });
  }

  void logCrash({required String errorSummary}) {
    logEvent('app_crash', {
      'summary': errorSummary,
    });
  }

  void clear() {
    _eventLog.clear();
  }
}
