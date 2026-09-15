import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Common event schema for all passive health data and manual logs.
/// Every ingested reading is strictly mapped to this contract.
class HealthEvent {
  final String id;
  final String metric; // e.g. 'heart_rate_variability', 'resting_heart_rate', 'sleep_duration', etc.
  final double value;
  final String unit; // e.g. 'ms', 'bpm', 'minutes', 'steps', 'celsius'
  final DateTime start; // timezone-aware UTC or local offset
  final DateTime end;
  final String source; // 'health_connect', 'healthkit', 'manual', 'simulated'
  final String sourceRecordId; // platform or client-generated unique id
  final double quality; // 0.0 to 1.0 confidence/sensor coverage for this sample
  final String modelVersion; // e.g. 'recovery-0.1.0'
  final Map<String, dynamic> metadata;

  HealthEvent({
    String? id,
    required this.metric,
    required this.value,
    required this.unit,
    required this.start,
    required this.end,
    required this.source,
    required this.sourceRecordId,
    this.quality = 1.0,
    this.modelVersion = 'recovery-0.1.0',
    this.metadata = const {},
  }) : id = id ?? _generateDeterministicId(metric, source, sourceRecordId, start);

  /// Deterministic ID ensuring that resyncing the same record never duplicates
  static String _generateDeterministicId(
    String metric,
    String source,
    String sourceRecordId,
    DateTime start,
  ) {
    final raw = '$metric|$source|$sourceRecordId|${start.toIso8601String()}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 24);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'metric': metric,
        'value': value,
        'unit': unit,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'source': source,
        'source_record_id': sourceRecordId,
        'quality': quality,
        'model_version': modelVersion,
        'metadata': metadata,
      };

  factory HealthEvent.fromJson(Map<String, dynamic> json) {
    return HealthEvent(
      id: json['id'] as String?,
      metric: json['metric'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      source: json['source'] as String,
      sourceRecordId: json['source_record_id'] as String,
      quality: (json['quality'] as num?)?.toDouble() ?? 1.0,
      modelVersion: json['model_version'] as String? ?? 'recovery-0.1.0',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HealthEvent($metric: $value $unit, source: $source, quality: $quality, start: $start)';
}
