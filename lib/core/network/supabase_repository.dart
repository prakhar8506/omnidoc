import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/health_event.dart';
import '../env/app_env.dart';

/// Abstract contract for backend operations. UI and state layers only interact
/// with this interface, never invoking Supabase client directly.
abstract class HealthBackendRepository {
  bool get isConfigured;
  String? get currentUserId;

  Future<void> initialize();

  // Auth Operations
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  });

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  // Data Operations
  Future<int> upsertHealthEvents(String userId, List<HealthEvent> events);
  Future<List<HealthEvent>> fetchHealthEvents(String userId, {String? metric, DateTime? since});

  Future<void> upsertScore({
    required String userId,
    required String scoreType,
    required double value,
    required double confidence,
    required List<Map<String, dynamic>> drivers,
    required Map<String, dynamic> inputs,
    required String modelVersion,
    required DateTime computedForDate,
  });

  Future<void> recordHabitLog({
    required String userId,
    required String behaviorKey,
    required bool value,
    required DateTime loggedAt,
  });

  Future<void> saveJournalEntry({
    required String userId,
    required String content,
    required String entryType,
    required String? mood,
    List<String> tags = const [],
  });

  Future<void> recordCheckIn({
    required String userId,
    required String checkInType,
    required int energy,
    required int soreness,
    required bool illnessFlag,
    required int stress,
    required int sleepQuality,
  });
}

/// Production implementation of [HealthBackendRepository] backed by Supabase.
class SupabaseRepository implements HealthBackendRepository {
  SupabaseClient? _client;
  bool _initialized = false;

  SupabaseRepository({SupabaseClient? customClient}) : _client = customClient {
    if (customClient != null) {
      _initialized = true;
    }
  }

  @override
  bool get isConfigured => AppEnv.isSupabaseConfigured || _client != null;

  @override
  String? get currentUserId => _client?.auth.currentUser?.id;

  SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase is not initialized. Check AppEnv.isSupabaseConfigured.');
    }
    return _client!;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!AppEnv.isSupabaseConfigured) {
      debugPrint('[SupabaseRepository] Running in offline/local-only mode: missing credentials.');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppEnv.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('[SupabaseRepository] Successfully initialized Supabase client.');
    } catch (e) {
      debugPrint('[SupabaseRepository] Initialization failed: $e');
    }
  }

  @override
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    String bloodType = 'Unknown',
  }) async {
    if (!isConfigured || _client == null) return null;
    return await _client!.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'blood_type': bloodType,
      },
    );
  }

  @override
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConfigured || _client == null) return null;
    return await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    if (!isConfigured || _client == null) return;
    await _client!.auth.signOut();
  }

  @override
  Future<int> upsertHealthEvents(String userId, List<HealthEvent> events) async {
    if (!isConfigured || _client == null || events.isEmpty) return 0;

    final rows = events.map((e) {
      return {
        'user_id': userId,
        'metric': e.metric,
        'value': e.value,
        'unit': e.unit,
        'start_time': e.start.toIso8601String(),
        'end_time': e.end.toIso8601String(),
        'source': e.source,
        'source_record_id': e.sourceRecordId,
        'quality': e.quality,
        'model_version': e.modelVersion,
        'metadata': e.metadata,
      };
    }).toList();

    try {
      // Upsert on unique (user_id, source, source_record_id)
      final res = await _client!.from('health_events').upsert(
        rows,
        onConflict: 'user_id,source,source_record_id',
      ).select('id');
      return (res as List).length;
    } catch (e) {
      debugPrint('[SupabaseRepository] upsertHealthEvents error: $e');
      return 0;
    }
  }

  @override
  Future<List<HealthEvent>> fetchHealthEvents(
    String userId, {
    String? metric,
    DateTime? since,
  }) async {
    if (!isConfigured || _client == null) return [];

    try {
      var query = _client!.from('health_events').select().eq('user_id', userId);
      if (metric != null) {
        query = query.eq('metric', metric);
      }
      if (since != null) {
        query = query.gte('start_time', since.toIso8601String());
      }
      final rows = await query.order('start_time', ascending: false);
      return (rows as List).map((row) {
        final r = Map<String, dynamic>.from(row as Map);
        return HealthEvent(
          id: r['id'] as String?,
          metric: r['metric'] as String,
          value: (r['value'] as num).toDouble(),
          unit: r['unit'] as String,
          start: DateTime.parse(r['start_time'] as String),
          end: DateTime.parse(r['end_time'] as String),
          source: r['source'] as String,
          sourceRecordId: r['source_record_id'] as String? ?? '',
          quality: (r['quality'] as num?)?.toDouble() ?? 1.0,
          modelVersion: r['model_version'] as String? ?? 'recovery-0.1.0',
          metadata: Map<String, dynamic>.from(r['metadata'] as Map? ?? {}),
        );
      }).toList();
    } catch (e) {
      debugPrint('[SupabaseRepository] fetchHealthEvents error: $e');
      return [];
    }
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
    if (!isConfigured || _client == null) return;

    final dateStr = '${computedForDate.year}-${computedForDate.month.toString().padLeft(2, '0')}-${computedForDate.day.toString().padLeft(2, '0')}';
    final payload = {
      'user_id': userId,
      'score_type': scoreType,
      'value': value,
      'confidence': confidence,
      'drivers': drivers,
      'inputs': inputs,
      'model_version': modelVersion,
      'computed_for_date': dateStr,
    };

    try {
      await _client!.from('scores').upsert(
        payload,
        onConflict: 'user_id,score_type,computed_for_date',
      );
    } catch (e) {
      debugPrint('[SupabaseRepository] upsertScore error: $e');
    }
  }

  @override
  Future<void> recordHabitLog({
    required String userId,
    required String behaviorKey,
    required bool value,
    required DateTime loggedAt,
  }) async {
    if (!isConfigured || _client == null) return;
    try {
      await _client!.from('habit_logs').insert({
        'user_id': userId,
        'behavior_key': behaviorKey,
        'value': value,
        'logged_at': loggedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseRepository] recordHabitLog error: $e');
    }
  }

  @override
  Future<void> saveJournalEntry({
    required String userId,
    required String content,
    required String entryType,
    required String? mood,
    List<String> tags = const [],
  }) async {
    if (!isConfigured || _client == null) return;
    try {
      await _client!.from('journal_entries').insert({
        'user_id': userId,
        'content': content,
        'entry_type': entryType,
        'mood': mood,
        'tags': tags,
      });
    } catch (e) {
      debugPrint('[SupabaseRepository] saveJournalEntry error: $e');
    }
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
    if (!isConfigured || _client == null) return;
    try {
      await _client!.from('check_ins').insert({
        'user_id': userId,
        'check_in_type': checkInType,
        'energy': energy,
        'soreness': soreness,
        'illness_flag': illnessFlag,
        'stress': stress,
        'sleep_quality': sleepQuality,
      });
    } catch (e) {
      debugPrint('[SupabaseRepository] recordCheckIn error: $e');
    }
  }
}
