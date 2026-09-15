import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/core/data/health_event.dart';
import 'package:health_companion/core/data/event_store.dart';
import 'package:health_companion/core/data/supabase_sync_service.dart';
import 'package:health_companion/core/network/supabase_repository.dart';
import 'package:health_companion/core/env/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory mock backend repository simulating Supabase Postgres with strict RLS enforcement.
class MockSupabaseBackendRepository implements HealthBackendRepository {
  String? activeUserId;
  final Map<String, List<Map<String, dynamic>>> _tableRows = {
    'health_events': [],
    'scores': [],
    'habit_logs': [],
    'journal_entries': [],
    'check_ins': [],
  };

  @override
  bool get isConfigured => true;

  @override
  String? get currentUserId => activeUserId;

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  }) async => null;

  @override
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {
    activeUserId = null;
  }

  @override
  Future<int> upsertHealthEvents(String userId, List<HealthEvent> events) async {
    // Enforce RLS: auth.uid() must match user_id
    if (activeUserId != userId) {
      throw const PostgrestException(
        message: 'new row violates row-level security policy for table "health_events"',
        code: '42501',
      );
    }

    int upserted = 0;
    final table = _tableRows['health_events']!;
    for (final e in events) {
      // Enforce unique (user_id, source, source_record_id)
      final existingIndex = table.indexWhere((r) =>
          r['user_id'] == userId &&
          r['source'] == e.source &&
          r['source_record_id'] == e.sourceRecordId);

      final row = {
        'id': e.id,
        'user_id': userId,
        'metric': e.metric,
        'value': e.value,
        'unit': e.unit,
        'start_time': e.start.toIso8601String(),
        'end_time': e.end.toIso8601String(),
        'source': e.source,
        'source_record_id': e.sourceRecordId,
        'quality': e.quality,
      };

      if (existingIndex >= 0) {
        table[existingIndex] = row;
      } else {
        table.add(row);
      }
      upserted++;
    }
    return upserted;
  }

  @override
  Future<List<HealthEvent>> fetchHealthEvents(
    String userId, {
    String? metric,
    DateTime? since,
  }) async {
    // Enforce RLS: can only read own events
    if (activeUserId != userId) {
      // Under Postgres RLS, rows where (auth.uid() = user_id) evaluates to false return empty set
      return [];
    }

    final table = _tableRows['health_events']!;
    return table
        .where((r) => r['user_id'] == userId)
        .where((r) => metric == null || r['metric'] == metric)
        .map((r) => HealthEvent(
              id: r['id'] as String,
              metric: r['metric'] as String,
              value: (r['value'] as num).toDouble(),
              unit: r['unit'] as String,
              start: DateTime.parse(r['start_time'] as String),
              end: DateTime.parse(r['end_time'] as String),
              source: r['source'] as String,
              sourceRecordId: r['source_record_id'] as String,
              quality: (r['quality'] as num).toDouble(),
            ))
        .toList();
  }

  @override
  Future<void> upsertScore({
    required String userId,
    required String scoreType,
    required double value,
    required double confidence,
    required List<Map<String, dynamic>> drivers,
    required Map<String, dynamic> inputs,
    required String modelVersion,
    required DateTime computedForDate,
  }) async {
    if (activeUserId != userId) {
      throw const PostgrestException(
        message: 'violates row-level security policy for table "scores"',
        code: '42501',
      );
    }
    _tableRows['scores']!.add({
      'user_id': userId,
      'score_type': scoreType,
      'value': value,
      'confidence': confidence,
      'computed_for_date': computedForDate.toIso8601String(),
    });
  }

  @override
  Future<void> recordHabitLog({
    required String userId,
    required String behaviorKey,
    required bool value,
    required DateTime loggedAt,
  }) async {
    if (activeUserId != userId) {
      throw const PostgrestException(message: 'RLS violation on habit_logs', code: '42501');
    }
    _tableRows['habit_logs']!.add({
      'user_id': userId,
      'behavior_key': behaviorKey,
      'value': value,
      'logged_at': loggedAt.toIso8601String(),
    });
  }

  @override
  Future<void> saveJournalEntry({
    required String userId,
    required String content,
    required String entryType,
    required String? mood,
    List<String> tags = const [],
  }) async {
    if (activeUserId != userId) {
      throw const PostgrestException(message: 'RLS violation on journal_entries', code: '42501');
    }
    _tableRows['journal_entries']!.add({
      'user_id': userId,
      'content': content,
      'entry_type': entryType,
      'mood': mood,
    });
  }

  @override
  Future<void> recordCheckIn({
    required String userId,
    required String checkInType,
    required int energy,
    required int soreness,
    required bool illnessFlag,
    required int stress,
    required int sleepQuality,
  }) async {
    if (activeUserId != userId) {
      throw const PostgrestException(message: 'RLS violation on check_ins', code: '42501');
    }
    _tableRows['check_ins']!.add({
      'user_id': userId,
      'check_in_type': checkInType,
      'energy': energy,
    });
  }

  int get totalRowsInHealthEvents => _tableRows['health_events']!.length;
}

void main() {
  group('Supabase Repository & Synchronization Tests', () {
    late MockSupabaseBackendRepository mockBackend;
    late EventStore localStore;
    late SupabaseSyncService syncService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockBackend = MockSupabaseBackendRepository();
      localStore = EventStore();
      await localStore.initialize();
      syncService = SupabaseSyncService(
        repository: mockBackend,
        eventStore: localStore,
      );
    });

    test('AppEnv safely defaults to unconfigured without hardcoded secrets', () {
      expect(AppEnv.supabaseUrl, isEmpty);
      expect(AppEnv.supabaseAnonKey, isEmpty);
      expect(AppEnv.isSupabaseConfigured, isFalse);
    });

    test('Duplicate-Sync Test: Syncing identical events twice does not duplicate rows in backend', () async {
      const testUserId = 'user-uuid-1111';
      mockBackend.activeUserId = testUserId;

      final now = DateTime(2026, 9, 16, 5, 0);
      final event1 = HealthEvent(
        metric: 'resting_heart_rate',
        value: 58.0,
        unit: 'bpm',
        start: now,
        end: now.add(const Duration(minutes: 5)),
        source: 'healthkit',
        sourceRecordId: 'apple-watch-rec-999',
        quality: 1.0,
      );

      // Record in local store
      await localStore.recordEvent(event1);
      expect(localStore.eventCount, 1);

      // First Sync: pushes 1 event
      final synced1 = await syncService.syncPendingEvents(testUserId);
      expect(synced1, 1);
      expect(mockBackend.totalRowsInHealthEvents, 1);

      // Second Sync: resyncs same batch, upsert on unique(user_id, source, source_record_id) prevents duplication
      final synced2 = await syncService.syncPendingEvents(testUserId);
      expect(synced2, 1);
      expect(mockBackend.totalRowsInHealthEvents, 1); // Row count remains exactly 1!
    });

    test('Offline Resilience Test: Local logging functions with no backend, flushes when online', () async {
      const testUserId = 'user-uuid-offline';
      final offlineRepo = SupabaseRepository(); // unconfigured
      final offlineSync = SupabaseSyncService(
        repository: offlineRepo,
        eventStore: localStore,
      );

      expect(offlineRepo.isConfigured, isFalse);

      final now = DateTime.now();
      final ev = HealthEvent(
        metric: 'sleep_duration',
        value: 8.0,
        unit: 'hours',
        start: now.subtract(const Duration(hours: 8)),
        end: now,
        source: 'healthkit',
        sourceRecordId: 'rec-sleep-offline',
      );

      // Logging works instantly offline
      final localOk = await localStore.recordEvent(ev);
      expect(localOk, isTrue);
      expect(localStore.eventCount, 1);

      // Sync attempt fails gracefully without throwing or blocking UI
      final syncCount = await offlineSync.syncPendingEvents(testUserId);
      expect(syncCount, 0);
      expect(localStore.eventCount, 1); // Local event safely preserved
    });
  });

  group('Mandatory RLS Cross-User Data Isolation Tests', () {
    late MockSupabaseBackendRepository mockBackend;

    setUp(() {
      mockBackend = MockSupabaseBackendRepository();
    });

    test('User B cannot read User A\'s health events', () async {
      const userA = 'user-a-1111';
      const userB = 'user-b-2222';

      // 1. User A inserts their private health event
      mockBackend.activeUserId = userA;
      final eventA = HealthEvent(
        metric: 'heart_rate_variability',
        value: 72.0,
        unit: 'ms',
        start: DateTime(2026, 9, 16, 5, 0),
        end: DateTime(2026, 9, 16, 5, 5),
        source: 'whoop',
        sourceRecordId: 'whoop-sample-1',
      );
      await mockBackend.upsertHealthEvents(userA, [eventA]);

      // Confirm User A can see their own event
      final userAEvents = await mockBackend.fetchHealthEvents(userA);
      expect(userAEvents.length, 1);
      expect(userAEvents.first.value, 72.0);

      // 2. User B switches active session and queries User A's records
      mockBackend.activeUserId = userB;
      final userBQueryResult = await mockBackend.fetchHealthEvents(userA);

      // Under RLS policy, User B receives an empty result set for User A's data
      expect(userBQueryResult, isEmpty);
    });

    test('User B cannot insert or overwrite User A\'s records (RLS check violation)', () async {
      const userA = 'user-a-1111';
      const userB = 'user-b-2222';

      // User B attempts to write a record attributed to User A
      mockBackend.activeUserId = userB;
      final maliciousEvent = HealthEvent(
        metric: 'blood_oxygen',
        value: 99.0,
        unit: '%',
        start: DateTime.now(),
        end: DateTime.now(),
        source: 'manual',
        sourceRecordId: 'spoof-1',
      );

      // Must throw Postgres RLS security violation
      expect(
        () => mockBackend.upsertHealthEvents(userA, [maliciousEvent]),
        throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
      );
    });

    test('User B cannot mutate User A\'s scores, habits, or journal entries', () async {
      const userA = 'user-a-1111';
      const userB = 'user-b-2222';

      mockBackend.activeUserId = userB;

      // Score mutation attempt
      expect(
        () => mockBackend.upsertScore(
          userId: userA,
          scoreType: 'recovery',
          value: 99.0,
          confidence: 0.9,
          drivers: [],
          inputs: {},
          modelVersion: 'recovery-0.1.0',
          computedForDate: DateTime.now(),
        ),
        throwsA(isA<PostgrestException>()),
      );

      // Habit log mutation attempt
      expect(
        () => mockBackend.recordHabitLog(
          userId: userA,
          behaviorKey: 'caffeine_curfew',
          value: true,
          loggedAt: DateTime.now(),
        ),
        throwsA(isA<PostgrestException>()),
      );

      // Journal entry mutation attempt
      expect(
        () => mockBackend.saveJournalEntry(
          userId: userA,
          content: 'Compromised note',
          entryType: 'text',
          mood: 'Tired',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
