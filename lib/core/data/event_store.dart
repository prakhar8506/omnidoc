import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_event.dart';

/// Offline-first append-only local event log with deduplication,
/// deterministic conflict resolution, and persistent storage.
class EventStore {
  static const String _storageKey = 'hc_recovery_event_log';
  final Map<String, HealthEvent> _eventsById = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int get eventCount => _eventsById.length;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      for (final raw in rawList) {
        try {
          final event = HealthEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          _eventsById[event.id] = event;
        } catch (e) {
          debugPrint('Failed to deserialize event: $e');
        }
      }
    } catch (e) {
      debugPrint('EventStore init error: $e');
    } finally {
      _isInitialized = true;
    }
  }

  /// Inserts a single event with deduplication and conflict resolution.
  /// Returns true if added or updated, false if discarded as lower priority.
  Future<bool> recordEvent(HealthEvent newEvent) async {
    if (!_isInitialized) await initialize();

    // 1. Exact ID Deduplication check
    if (_eventsById.containsKey(newEvent.id)) {
      final existing = _eventsById[newEvent.id]!;
      // If exactly identical or lower quality, discard duplicate
      if (newEvent.quality <= existing.quality) {
        return false;
      }
    }

    // 2. Window-based conflict resolution for the same metric
    // If a manual record and a wearable record overlap for the same metric & window:
    // Wearable hardware > Manual, and higher quality > lower quality.
    final conflicting = _findConflictingEvent(newEvent);
    if (conflicting != null) {
      final isWearablePreferred = (newEvent.source == 'health_connect' || newEvent.source == 'healthkit') &&
          conflicting.source == 'manual';
      final isHigherQuality = newEvent.quality > conflicting.quality;

      if (!isWearablePreferred && !isHigherQuality && conflicting.source != 'manual') {
        // Discard incoming lower priority conflict
        return false;
      }
      // Replace conflicting event
      _eventsById.remove(conflicting.id);
    }

    _eventsById[newEvent.id] = newEvent;
    await _persist();
    return true;
  }

  /// Batch record events with deduplication
  Future<int> recordEvents(List<HealthEvent> events) async {
    if (!_isInitialized) await initialize();
    int added = 0;
    for (final event in events) {
      final ok = await recordEvent(event);
      if (ok) added++;
    }
    return added;
  }

  HealthEvent? _findConflictingEvent(HealthEvent incoming) {
    for (final existing in _eventsById.values) {
      if (existing.metric == incoming.metric && existing.id != incoming.id) {
        // Check if windows overlap or timestamps occur within the same 15-minute window
        final overlaps = incoming.start.isBefore(existing.end) && incoming.end.isAfter(existing.start);
        final isNearInTime = incoming.start.difference(existing.start).abs() <= const Duration(minutes: 15);
        if (overlaps || isNearInTime) {
          return existing;
        }
      }
    }
    return null;
  }

  List<HealthEvent> getEventsForMetric(
    String metric, {
    DateTime? since,
    DateTime? until,
  }) {
    final list = _eventsById.values.where((e) {
      if (e.metric != metric) return false;
      if (since != null && e.end.isBefore(since)) return false;
      if (until != null && e.start.isAfter(until)) return false;
      return true;
    }).toList();

    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  List<HealthEvent> getEventsForRange(DateTime start, DateTime end) {
    final list = _eventsById.values.where((e) {
      return e.start.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.end.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  List<HealthEvent> getAllEvents() {
    final list = _eventsById.values.toList();
    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  Future<void> clear() async {
    _eventsById.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = _eventsById.values.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, serialized);
    } catch (e) {
      debugPrint('EventStore persist error: $e');
    }
  }
}
