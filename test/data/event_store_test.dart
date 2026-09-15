import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/core/data/health_event.dart';
import 'package:health_companion/core/data/event_store.dart';

void main() {
  group('EventStore Tests', () {
    late EventStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = EventStore();
      await store.initialize();
    });

    test('Deduplication: adding exact identical event twice yields only 1 event', () async {
      final now = DateTime.now();
      final ev1 = HealthEvent(
        id: 'dup-1',
        metric: 'resting_heart_rate',
        value: 72.0,
        unit: 'bpm',
        start: now,
        end: now.add(const Duration(minutes: 5)),
        source: 'healthkit',
        sourceRecordId: 'rec-1',
        quality: 1.0,
      );

      final ev2 = HealthEvent(
        id: 'dup-1',
        metric: 'resting_heart_rate',
        value: 72.0,
        unit: 'bpm',
        start: now,
        end: now.add(const Duration(minutes: 5)),
        source: 'healthkit',
        sourceRecordId: 'rec-1',
        quality: 1.0,
      );

      final added1 = await store.recordEvent(ev1);
      final added2 = await store.recordEvent(ev2);

      expect(added1, isTrue);
      expect(added2, isFalse);
      expect(store.eventCount, 1);
    });

    test('Conflict resolution prefers hardware wearable over manual entry in same time window', () async {
      final fixedTime = DateTime(2026, 9, 15, 8, 0);

      final manualEvent = HealthEvent(
        id: 'manual-ev-1',
        metric: 'resting_heart_rate',
        value: 65.0,
        unit: 'bpm',
        start: fixedTime,
        end: fixedTime.add(const Duration(minutes: 5)),
        source: 'manual',
        sourceRecordId: 'man-1',
        quality: 0.6,
      );

      final watchEvent = HealthEvent(
        id: 'watch-ev-1',
        metric: 'resting_heart_rate',
        value: 58.0,
        unit: 'bpm',
        start: fixedTime.add(const Duration(minutes: 5)),
        end: fixedTime.add(const Duration(minutes: 10)),
        source: 'healthkit',
        sourceRecordId: 'hk-1',
        quality: 1.0,
      );

      await store.recordEvent(manualEvent);
      expect(store.eventCount, 1);

      // Appending watch event in same 15-minute window supersedes the manual event
      final addedWatch = await store.recordEvent(watchEvent);
      expect(addedWatch, isTrue);
      expect(store.eventCount, 1); // Manual was replaced

      final stored = store.getEventsForMetric('resting_heart_rate');
      expect(stored.first.source, 'healthkit');
      expect(stored.first.value, 58.0);
    });

    test('Querying by time range and metric returns expected slices', () async {
      final base = DateTime(2026, 9, 15, 12, 0);
      for (int i = 0; i < 5; i++) {
        final start = base.add(Duration(hours: i * 2));
        await store.recordEvent(HealthEvent(
          metric: 'steps',
          value: 1000.0 * (i + 1),
          unit: 'steps',
          start: start,
          end: start.add(const Duration(hours: 1)),
          source: 'healthkit',
          sourceRecordId: 'rec-step-$i',
          quality: 1.0,
        ));
      }

      await store.recordEvent(HealthEvent(
        metric: 'sleep_duration',
        value: 7.5,
        unit: 'hours',
        start: base,
        end: base.add(const Duration(hours: 8)),
        source: 'healthkit',
        sourceRecordId: 'rec-sleep-1',
        quality: 1.0,
      ));

      final stepEvents = store.getEventsForMetric('steps');
      expect(stepEvents.length, 5);

      final windowEvents = store.getEventsForRange(
        base.add(const Duration(hours: 1)),
        base.add(const Duration(hours: 5)),
      );
      // Hours 2 and 4 should be inside
      expect(windowEvents.length, 2);
    });
  });
}
